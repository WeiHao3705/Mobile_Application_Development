# 🔓 DISABLE RLS - COPY/PASTE READY

## Quick Copy-Paste Commands

### Command 1: Disable RLS (Testing)
```sql
ALTER TABLE "User" DISABLE ROW LEVEL SECURITY;
```

### Command 2: Add Public Read Policy (Production)
```sql
CREATE POLICY "Allow public read access" ON "User" FOR SELECT USING (true);
```

### Command 3: Verify RLS Status
```sql
SELECT tablename, rowsecurity FROM pg_tables WHERE tablename = 'User';
```

### Command 4: Check Policies
```sql
SELECT * FROM pg_policies WHERE tablename = 'User';
```

### Command 5: Verify Data Exists
```sql
SELECT * FROM "User";
```

---

## Steps:
1. Go to Supabase Dashboard
2. Open SQL Editor
3. Copy Command 1 (Disable RLS)
4. Paste in SQL Editor
5. Click Run
6. Refresh Flutter app
7. Users appear! ✅

---

**That's it!** 🚀

