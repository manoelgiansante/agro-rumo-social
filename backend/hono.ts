import { trpcServer } from "@hono/trpc-server";
import { Hono } from "hono";
import { cors } from "hono/cors";
import crypto from "crypto";

import { appRouter } from "./trpc/app-router";
import { createContext } from "./trpc/create-context";

const app = new Hono();

app.use("*", cors({
  origin: (origin) => {
    // Permitir requests sem origin (mobile apps, curl, etc)
    if (!origin) return "*";
    // Permitir dominio do projeto e localhost para dev
    const allowed = [
      /\.vercel\.app$/,
      /^https?:\/\/localhost(:\d+)?$/,
      /^https?:\/\/127\.0\.0\.1(:\d+)?$/,
    ];
    return allowed.some((re) => re.test(origin)) ? origin : "";
  },
  allowMethods: ["GET", "POST", "PATCH", "DELETE", "OPTIONS"],
  allowHeaders: ["Content-Type", "Authorization"],
  maxAge: 86400,
}));

app.use(
  "/trpc/*",
  trpcServer({
    endpoint: "/api/trpc",
    router: appRouter,
    createContext,
  }),
);

app.get("/", (c) => {
  return c.json({ status: "ok", message: "ControleSocial API is running" });
});

// ─── In-memory state store for OAuth CSRF protection ───
const stateStore = new Map<string, { userId: string; platform: string; createdAt: number }>();

// Clean up expired states every 10 minutes
setInterval(() => {
  const now = Date.now();
  for (const [key, val] of stateStore.entries()) {
    if (now - val.createdAt > 10 * 60 * 1000) {
      stateStore.delete(key);
    }
  }
}, 10 * 60 * 1000);

// ─── Supabase helper ───
async function supabaseRequest(path: string, method: string, body?: any, useServiceRole = true) {
  const supabaseUrl = process.env.SUPABASE_URL || "";
  const serviceKey = process.env.SUPABASE_SERVICE_ROLE_KEY || "";
  const anonKey = process.env.SUPABASE_ANON_KEY || "";

  const url = `${supabaseUrl}/rest/v1/${path}`;
  const headers: Record<string, string> = {
    "Content-Type": "application/json",
    "apikey": anonKey,
    "Authorization": `Bearer ${useServiceRole ? serviceKey : anonKey}`,
    "Prefer": "return=representation",
  };

  const res = await fetch(url, {
    method,
    headers,
    body: body ? JSON.stringify(body) : undefined,
  });

  if (!res.ok) {
    const errorBody = await res.text();
    throw new Error(`Supabase ${method} ${path} failed: ${res.status} - ${errorBody}`);
  }

  return res.json();
}

// ═══════════════════════════════════════════════════════════
// META (Facebook + Instagram) OAuth
// ═══════════════════════════════════════════════════════════

app.get("/oauth/meta/start", (c) => {
  const userId = c.req.query("userId") || "";
  const metaAppId = process.env.META_APP_ID || "";
  const apiBaseUrl = process.env.EXPO_PUBLIC_RORK_API_BASE_URL || "";

  if (!metaAppId) {
    return c.json({ error: "META_APP_ID not configured" }, 500);
  }

  const state = crypto.randomBytes(24).toString("hex");
  stateStore.set(state, { userId, platform: "meta", createdAt: Date.now() });

  const redirectUri = `${apiBaseUrl}/api/oauth/meta/callback`;
  const scope = [
    "pages_show_list",
    "pages_read_engagement",
    "pages_manage_posts",
    "instagram_basic",
    "instagram_content_publish",
    "instagram_manage_insights",
  ].join(",");

  const authUrl =
    `https://www.facebook.com/v21.0/dialog/oauth` +
    `?client_id=${encodeURIComponent(metaAppId)}` +
    `&redirect_uri=${encodeURIComponent(redirectUri)}` +
    `&state=${encodeURIComponent(state)}` +
    `&scope=${encodeURIComponent(scope)}` +
    `&response_type=code`;

  return c.redirect(authUrl);
});

app.get("/oauth/meta/callback", async (c) => {
  const code = c.req.query("code") || "";
  const state = c.req.query("state") || "";
  const error = c.req.query("error");

  if (error) {
    return c.redirect(`controlesocial://oauth-callback?success=false&error=${encodeURIComponent(error)}`);
  }

  const session = stateStore.get(state);
  if (!session) {
    return c.redirect(`controlesocial://oauth-callback?success=false&error=invalid_state`);
  }
  stateStore.delete(state);

  const metaAppId = process.env.META_APP_ID || "";
  const metaAppSecret = process.env.META_APP_SECRET || "";
  const apiBaseUrl = process.env.EXPO_PUBLIC_RORK_API_BASE_URL || "";
  const redirectUri = `${apiBaseUrl}/api/oauth/meta/callback`;

  try {
    // 1. Exchange code for short-lived token
    const tokenUrl =
      `https://graph.facebook.com/v21.0/oauth/access_token` +
      `?client_id=${encodeURIComponent(metaAppId)}` +
      `&client_secret=${encodeURIComponent(metaAppSecret)}` +
      `&redirect_uri=${encodeURIComponent(redirectUri)}` +
      `&code=${encodeURIComponent(code)}`;

    const tokenResp = await fetch(tokenUrl);
    const tokenJson: any = await tokenResp.json();

    if (!tokenResp.ok || !tokenJson.access_token) {
      const errMsg = tokenJson.error?.message || "token_exchange_failed";
      return c.redirect(`controlesocial://oauth-callback?success=false&error=${encodeURIComponent(errMsg)}`);
    }

    const shortLivedToken = tokenJson.access_token;

    // 2. Exchange for long-lived token
    const longLivedUrl =
      `https://graph.facebook.com/v21.0/oauth/access_token` +
      `?grant_type=fb_exchange_token` +
      `&client_id=${encodeURIComponent(metaAppId)}` +
      `&client_secret=${encodeURIComponent(metaAppSecret)}` +
      `&fb_exchange_token=${encodeURIComponent(shortLivedToken)}`;

    const longLivedResp = await fetch(longLivedUrl);
    const longLivedJson: any = await longLivedResp.json();

    const accessToken = longLivedJson.access_token || shortLivedToken;
    const expiresIn = longLivedJson.expires_in || tokenJson.expires_in || 5184000;

    // 3. Get user's pages
    const pagesResp = await fetch(
      `https://graph.facebook.com/v21.0/me/accounts?access_token=${encodeURIComponent(accessToken)}`
    );
    const pagesJson: any = await pagesResp.json();
    const pages = pagesJson.data || [];

    let savedPlatforms: string[] = [];

    for (const page of pages) {
      const pageToken = page.access_token;
      const pageId = page.id;
      const pageName = page.name;

      // Save Facebook page account
      if (session.userId) {
        await supabaseRequest("social_accounts", "POST", {
          user_id: session.userId,
          platform: "facebook",
          account_name: pageName || "Página Facebook",
          account_id: pageId,
          access_token: pageToken,
          token_expires_at: new Date(Date.now() + expiresIn * 1000).toISOString(),
          page_id: pageId,
          is_active: true,
        });
        savedPlatforms.push("facebook");
      }

      // 4. Check for connected Instagram Business account
      const igResp = await fetch(
        `https://graph.facebook.com/v21.0/${pageId}?fields=instagram_business_account&access_token=${encodeURIComponent(pageToken)}`
      );
      const igJson: any = await igResp.json();

      if (igJson.instagram_business_account?.id) {
        const igId = igJson.instagram_business_account.id;

        // Get IG username
        const igInfoResp = await fetch(
          `https://graph.facebook.com/v21.0/${igId}?fields=username,name&access_token=${encodeURIComponent(pageToken)}`
        );
        const igInfo: any = await igInfoResp.json();

        if (session.userId) {
          await supabaseRequest("social_accounts", "POST", {
            user_id: session.userId,
            platform: "instagram",
            account_name: igInfo.username ? `@${igInfo.username}` : "Instagram Business",
            account_id: igId,
            access_token: pageToken,
            token_expires_at: new Date(Date.now() + expiresIn * 1000).toISOString(),
            page_id: pageId,
            is_active: true,
          });
          savedPlatforms.push("instagram");
        }
      }
    }

    const platformsStr = savedPlatforms.join(",");
    return c.redirect(
      `controlesocial://oauth-callback?success=true&platform=meta&connected=${encodeURIComponent(platformsStr)}`
    );
  } catch (err: any) {
    const errMsg = err.message || "unknown_error";
    return c.redirect(`controlesocial://oauth-callback?success=false&error=${encodeURIComponent(errMsg)}`);
  }
});

// ═══════════════════════════════════════════════════════════
// TikTok OAuth
// ═══════════════════════════════════════════════════════════

app.get("/oauth/tiktok/start", (c) => {
  const userId = c.req.query("userId") || "";
  const clientKey = process.env.TIKTOK_CLIENT_KEY || "";
  const apiBaseUrl = process.env.EXPO_PUBLIC_RORK_API_BASE_URL || "";

  if (!clientKey) {
    return c.json({ error: "TIKTOK_CLIENT_KEY not configured" }, 500);
  }

  const state = crypto.randomBytes(24).toString("hex");
  stateStore.set(state, { userId, platform: "tiktok", createdAt: Date.now() });

  const redirectUri = `${apiBaseUrl}/api/oauth/tiktok/callback`;
  const scope = "user.info.basic,video.publish,video.upload";

  const authUrl =
    `https://www.tiktok.com/v2/auth/authorize/` +
    `?client_key=${encodeURIComponent(clientKey)}` +
    `&response_type=code` +
    `&scope=${encodeURIComponent(scope)}` +
    `&redirect_uri=${encodeURIComponent(redirectUri)}` +
    `&state=${encodeURIComponent(state)}`;

  return c.redirect(authUrl);
});

app.get("/oauth/tiktok/callback", async (c) => {
  const code = c.req.query("code") || "";
  const state = c.req.query("state") || "";
  const error = c.req.query("error");

  if (error) {
    return c.redirect(`controlesocial://oauth-callback?success=false&error=${encodeURIComponent(error)}`);
  }

  const session = stateStore.get(state);
  if (!session) {
    return c.redirect(`controlesocial://oauth-callback?success=false&error=invalid_state`);
  }
  stateStore.delete(state);

  const clientKey = process.env.TIKTOK_CLIENT_KEY || "";
  const clientSecret = process.env.TIKTOK_CLIENT_SECRET || "";
  const apiBaseUrl = process.env.EXPO_PUBLIC_RORK_API_BASE_URL || "";
  const redirectUri = `${apiBaseUrl}/api/oauth/tiktok/callback`;

  try {
    // Exchange code for token
    const body = new URLSearchParams({
      client_key: clientKey,
      client_secret: clientSecret,
      code,
      grant_type: "authorization_code",
      redirect_uri: redirectUri,
    });

    const tokenResp = await fetch("https://open.tiktokapis.com/v2/oauth/token/", {
      method: "POST",
      headers: { "Content-Type": "application/x-www-form-urlencoded" },
      body,
    });

    const tokenJson: any = await tokenResp.json();

    if (tokenJson.error || !tokenJson.access_token) {
      const errMsg = tokenJson.error_description || tokenJson.error || "token_exchange_failed";
      return c.redirect(`controlesocial://oauth-callback?success=false&error=${encodeURIComponent(errMsg)}`);
    }

    const accessToken = tokenJson.access_token;
    const refreshToken = tokenJson.refresh_token;
    const openId = tokenJson.open_id;
    const expiresIn = tokenJson.expires_in || 86400;

    // Get user info
    let displayName = "@tiktok_user";
    try {
      const userResp = await fetch(
        "https://open.tiktokapis.com/v2/user/info/?fields=display_name,avatar_url",
        {
          headers: { Authorization: `Bearer ${accessToken}` },
        }
      );
      const userJson: any = await userResp.json();
      if (userJson.data?.user?.display_name) {
        displayName = `@${userJson.data.user.display_name}`;
      }
    } catch {}

    // Save to Supabase
    if (session.userId) {
      await supabaseRequest("social_accounts", "POST", {
        user_id: session.userId,
        platform: "tiktok",
        account_name: displayName,
        account_id: openId || "",
        access_token: accessToken,
        refresh_token: refreshToken,
        token_expires_at: new Date(Date.now() + expiresIn * 1000).toISOString(),
        is_active: true,
      });
    }

    return c.redirect(
      `controlesocial://oauth-callback?success=true&platform=tiktok&account_name=${encodeURIComponent(displayName)}`
    );
  } catch (err: any) {
    const errMsg = err.message || "unknown_error";
    return c.redirect(`controlesocial://oauth-callback?success=false&error=${encodeURIComponent(errMsg)}`);
  }
});

// ═══════════════════════════════════════════════════════════
// Token Refresh endpoint (called by cron or app)
// ═══════════════════════════════════════════════════════════

app.post("/oauth/refresh-tokens", async (c) => {
  const supabaseUrl = process.env.SUPABASE_URL || "";
  const serviceKey = process.env.SUPABASE_SERVICE_ROLE_KEY || "";
  const anonKey = process.env.SUPABASE_ANON_KEY || "";

  try {
    // Fetch accounts expiring within 7 days
    const sevenDaysFromNow = new Date(Date.now() + 7 * 24 * 60 * 60 * 1000).toISOString();
    const accounts = (await supabaseRequest(
      `social_accounts?is_active=eq.true&token_expires_at=lt.${sevenDaysFromNow}&select=*`,
      "GET"
    )) as any[];

    let refreshed = 0;
    let failed = 0;

    for (const account of accounts) {
      try {
        if (account.platform === "tiktok" && account.refresh_token) {
          const clientKey = process.env.TIKTOK_CLIENT_KEY || "";
          const clientSecret = process.env.TIKTOK_CLIENT_SECRET || "";

          const body = new URLSearchParams({
            client_key: clientKey,
            client_secret: clientSecret,
            grant_type: "refresh_token",
            refresh_token: account.refresh_token,
          });

          const resp = await fetch("https://open.tiktokapis.com/v2/oauth/token/", {
            method: "POST",
            headers: { "Content-Type": "application/x-www-form-urlencoded" },
            body,
          });

          const json: any = await resp.json();
          if (json.access_token) {
            await supabaseRequest(`social_accounts?id=eq.${account.id}`, "PATCH", {
              access_token: json.access_token,
              refresh_token: json.refresh_token || account.refresh_token,
              token_expires_at: new Date(Date.now() + (json.expires_in || 86400) * 1000).toISOString(),
            });
            refreshed++;
          } else {
            failed++;
          }
        }
        // Meta long-lived tokens last ~60 days; for now we just track expiry
      } catch {
        failed++;
      }
    }

    return c.json({ refreshed, failed });
  } catch (err: any) {
    return c.json({ error: err.message }, 500);
  }
});

export default app;
