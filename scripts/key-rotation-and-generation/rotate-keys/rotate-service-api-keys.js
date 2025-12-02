import { rotateApiKeys } from "./rotate-api-keys";

rotateApiKeys(true).catch(() => {
  process.exit(1);
});
