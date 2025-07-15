class SupabaseConfig {
  // Configuración de Supabase
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://yrmwixiqqroweurpkeyc.supabase.co',
  );
  
  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InlybXdpeGlxcXJvd2V1cnBrZXljIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDgzNzQ4MTYsImV4cCI6MjA2Mzk1MDgxNn0.veJOqJPNqMDKIJplD18Pcptbzljd0hdFjqINSxF_78E',
  );
}
