module.exports = async () => {
  /**
   * @type {import('next').NextConfig}
   */
  const nextConfig = {
    reactStrictMode: true,
  };

  const withPWA = await import('next-pwa').then((mod) =>
    mod.default({
      dest: 'public',
      register: true,
      skipWaiting: true,
      runtimeCaching: [
        {
          urlPattern: /^blob:http:\/\/localhost:3000\//, // blob URLを除外
          handler: 'NetworkOnly', // ネットワークからのみ取得
        },
        {
          urlPattern: /\.(?:png|jpg|jpeg|svg|gif)$/,
          handler: 'CacheFirst',
          options: {
            cacheName: 'images',
            expiration: {
              maxEntries: 50,
              maxAgeSeconds: 30 * 24 * 60 * 60, // 30日
            },
          },
        },
        {
          urlPattern: /\.(?:js|css)$/,
          handler: 'StaleWhileRevalidate',
          options: {
            cacheName: 'static-resources',
          },
        },
        // デフォルトのキャッシュ戦略
        {
          urlPattern: /^https?.*/,
          handler: 'NetworkFirst',
          options: {
            cacheName: 'default-cache',
            networkTimeoutSeconds: 10, // ネットワークから10秒以内にレスポンスがない場合はキャッシュを使用
            expiration: {
              maxEntries: 100,
              maxAgeSeconds: 7 * 24 * 60 * 60, // 7日
            },
          },
        },
      ],
    })
  );

  return withPWA(nextConfig);
};