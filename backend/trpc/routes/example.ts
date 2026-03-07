import { createTRPCRouter, publicProcedure } from "../create-context";

export const exampleRouter = createTRPCRouter({
  health: publicProcedure.query(() => {
    return { status: "ok", timestamp: new Date() };
  }),
});
