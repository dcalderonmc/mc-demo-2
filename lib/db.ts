import { neon } from '@neondatabase/serverless';

export function createNeonClient() {
  if (!process.env.DATABASE_URL) return null;
  return neon(process.env.DATABASE_URL);
}
type Db = ReturnType<typeof createNeonClient>;
const sql = createNeonClient();
export default sql as Db;
