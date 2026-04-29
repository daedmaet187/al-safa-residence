export default () => ({
  port: parseInt(process.env.PORT, 10) || 3000,
  nodeEnv: process.env.NODE_ENV || 'development',
  database: {
    url: process.env.DATABASE_URL,
  },
  jwt: {
    accessSecret: process.env.JWT_ACCESS_SECRET ?? (() => { throw new Error('JWT_ACCESS_SECRET is required'); })(),
    refreshSecret: process.env.JWT_REFRESH_SECRET ?? (() => { throw new Error('JWT_REFRESH_SECRET is required'); })(),
    accessExpiry: process.env.JWT_ACCESS_EXPIRY || '15m',
    refreshExpiry: process.env.JWT_REFRESH_EXPIRY || '7d',
  },
  aws: {
    region: process.env.AWS_REGION || 'eu-central-1',
    s3Bucket: process.env.AWS_S3_BUCKET || '',
  },
  fcm: {
    serverKey: process.env.FCM_SERVER_KEY || '',
  },
});
