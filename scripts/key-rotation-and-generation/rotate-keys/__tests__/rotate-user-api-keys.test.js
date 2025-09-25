import { when } from "jest-when";
import { rotateApiKeys } from "../rotate-api-keys";
import {
  getParamsByPath,
  getRotateApiKeyTag,
  removeRotateApiKeyTag,
  rotateApiKey,
} from "../../aws-clients/ssm-client";
import { initializeConfig } from "../../config";
import { restartServices } from "../../restart-services/restart-services";

jest.mock("../../aws-clients/ssm-client");
jest.mock("../../restart-services/restart-services");
jest.mock("../../config");

describe("rotateApiKeys", () => {
  initializeConfig.mockReturnValue({ nhsEnvironment: "env" });
  beforeEach(() => {
    when(getRotateApiKeyTag)
      .calledWith("/repo/env/api-keys/api-key-user/user")
      .mockResolvedValue(true)
      .calledWith("/repo/env/api-keys/api-key-user/user-1")
      .mockResolvedValue(false)
      .calledWith("/repo/env/api-keys/api-key-user/user-2")
      .mockResolvedValue(false);
  });
  afterEach(() => {
    getRotateApiKeyTag.mockRestore();
    rotateApiKey.mockRestore();
    removeRotateApiKeyTag.mockRestore();
    restartServices.mockRestore();
  });

  it("should rotate api key when the parameter is tagged with RotateApiKey", async () => {
    getParamsByPath.mockResolvedValueOnce([
      "/repo/env/api-keys/key",
      "/repo/env/api-keys/key-1",
      "/repo/env/api-keys/api-key-user/user",
      "/repo/env/api-keys/api-key-user/user-1",
    ]);

    await rotateApiKeys(false);

    expect(getParamsByPath).toHaveBeenCalledWith(
      "/repo/env/user-input/api-keys/"
    );
    expect(getRotateApiKeyTag).toHaveBeenCalledWith(
      "/repo/env/api-keys/api-key-user/user"
    );
    expect(getRotateApiKeyTag).toHaveBeenCalledWith(
      "/repo/env/api-keys/api-key-user/user-1"
    );
    expect(getRotateApiKeyTag).not.toHaveBeenCalledWith(
      "/repo/env/api-keys/key"
    );
    expect(getRotateApiKeyTag).not.toHaveBeenCalledWith(
      "/repo/env/api-keys/key-1"
    );

    expect(rotateApiKey).toHaveBeenCalledWith(
      "/repo/env/api-keys/api-key-user/user"
    );
    expect(rotateApiKey).not.toHaveBeenCalledWith(
      "/repo/env/api-keys/api-key-user/user-1"
    );
    expect(rotateApiKey).toHaveBeenCalledTimes(1);
    expect(removeRotateApiKeyTag).toHaveBeenCalledWith(
      "/repo/env/api-keys/api-key-user/user"
    );

    expect(restartServices).toHaveBeenCalledWith([
      "/repo/env/api-keys/api-key-user/user",
    ]);
    expect(restartServices).toHaveBeenCalledTimes(1);
  });

  it("should not rotate api key when the parameter is not tagged with RotateApiKey", async () => {
    getParamsByPath.mockResolvedValueOnce([
      "/repo/env/api-keys/api-key-user/user",
      "/repo/env/api-keys/api-key-user/user-1",
    ]);

    await rotateApiKeys(false);

    expect(getParamsByPath).toHaveBeenCalledWith(
      "/repo/env/user-input/api-keys/"
    );
    expect(rotateApiKey).not.toHaveBeenCalledWith(
      "/repo/env/api-keys/api-key-user/user-1"
    );
    expect(removeRotateApiKeyTag).not.toHaveBeenCalledWith(
      "/repo/env/api-keys/api-key-user/user-1"
    );
    expect(restartServices).not.toHaveBeenCalledWith([
      "/repo/env/api-keys/api-key-user/user-1",
    ]);
  });
  it("should not add to the list when not api-key-user and isService is false", async () => {
    getParamsByPath.mockResolvedValueOnce([
      "/repo/env/api-keys/api-key-user/user",
      "/repo/env/api-keys/api-key-user/user-1",
    ]);

    await rotateApiKeys(false);

    expect(getParamsByPath).toHaveBeenCalledWith(
      "/repo/env/user-input/api-keys/"
    );
    expect(rotateApiKey).not.toHaveBeenCalledWith(
      "/repo/env/api-keys/api-key-user/user-1"
    );
    expect(removeRotateApiKeyTag).not.toHaveBeenCalledWith(
      "/repo/env/api-keys/api-key-user/user-1"
    );
    expect(restartServices).not.toHaveBeenCalledWith([
      "/repo/env/api-keys/api-key-user/user-1",
    ]);
  });

  it("should not call rotateApiKey when there is no user api keys ", async () => {
    getParamsByPath.mockResolvedValueOnce([
      "/repo/env/api-keys/key",
      "/repo/env/api-keys/key-1",
    ]);

    await rotateApiKeys(false);

    expect(getParamsByPath).toHaveBeenCalledWith(
      "/repo/env/user-input/api-keys/"
    );
    expect(getRotateApiKeyTag).toHaveBeenCalledTimes(0);
    expect(getRotateApiKeyTag).not.toHaveBeenCalledWith(
      "/repo/env/api-keys/key"
    );
    expect(getRotateApiKeyTag).not.toHaveBeenCalledWith(
      "/repo/env/api-keys/key-1"
    );

    expect(rotateApiKey).toHaveBeenCalledTimes(0);
    expect(getRotateApiKeyTag).not.toHaveBeenCalledWith([]);
    expect(restartServices).toHaveBeenCalledWith([]);
  });
});
