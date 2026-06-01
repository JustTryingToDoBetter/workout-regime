module.exports = function handler(request, response) {
  response.setHeader('Content-Type', 'application/json');
  response.setHeader('Cache-Control', 'no-store');

  response.status(200).json({
    supabaseUrl: process.env.VITE_SUPABASE_URL || '',
    supabaseAnonKey: process.env.VITE_SUPABASE_ANON_KEY || ''
  });
};
