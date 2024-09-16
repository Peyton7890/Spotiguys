const { createProxyMiddleware } = require('http-proxy-middleware');

module.exports = function(app) {
  app.use(
    '/api',
    createProxyMiddleware({
      target: 'https://5dc724m422.execute-api.us-east-1.amazonaws.com',
      changeOrigin: true,
    })
  );
};