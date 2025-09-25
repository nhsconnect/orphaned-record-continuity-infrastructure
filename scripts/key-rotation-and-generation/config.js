export const initializeConfig = () => ({
  nhsEnvironment: process.env.NHS_ENVIRONMENT,
  isStrictEnvironment: !(process.env.NHS_ENVIRONMENT === 'dev' || process.env.NHS_ENVIRONMENT === 'test'
      || process.env.NHS_ENVIRONMENT === 'pre-prod' || process.env.NHS_ENVIRONMENT === 'perf')
});
