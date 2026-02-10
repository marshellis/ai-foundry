import NextAuth from "next-auth";
import GitHub from "next-auth/providers/github";

export const { handlers, signIn, signOut, auth } = NextAuth({
  providers: [
    GitHub({
      clientId: process.env.AUTH_GITHUB_ID!,
      clientSecret: process.env.AUTH_GITHUB_SECRET!,
    }),
  ],
  callbacks: {
    async session({ session, token }) {
      // Expose the GitHub username and avatar in the session
      if (token.sub) {
        session.user.id = token.sub;
      }
      if (token.picture) {
        session.user.image = token.picture;
      }
      if (token.login) {
        session.user.login = token.login as string;
      }
      return session;
    },
    async jwt({ token, profile }) {
      // On initial sign-in, persist the GitHub login (username) into the JWT
      if (profile) {
        token.login = (profile as { login?: string }).login;
      }
      return token;
    },
  },
});

// Extend the session types to include the GitHub login
declare module "next-auth" {
  interface Session {
    user: {
      id: string;
      name?: string | null;
      email?: string | null;
      image?: string | null;
      login?: string;
    };
  }
}
