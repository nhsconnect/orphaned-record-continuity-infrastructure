import { generateApiKeys } from "../generate-api-keys";
import {
  deleteApiKey,
  generateApiKey,
  getParam,
  getParamsByPath,
} from "../../aws-clients/ssm-client";
import { restartServices } from "../../restart-services/restart-services";
import * as h from "../../helpers";
import { when } from "jest-when";
import { initializeConfig } from "../../config";

jest.mock("../../aws-clients/ssm-client");
jest.mock("../../config");
jest.mock("../../helpers", () => ({
  ...jest.requireActual("../../helpers"),
  convertUserListToUserListParamArray: jest.fn(),
}));
jest.mock("../../restart-services/restart-services");

describe("generateUserApiKeys", () => {
  const apiKeysStringList = "al.pacino1,rob.deniro,joe.pesci";
  const usersAsArrayList = ["al.pacino1", "rob.deniro", "joe.pesci"];
  const ssmPath = `/repo/nhs-environment/user-input/repo-dev-list`;

  beforeEach(() => {
    when(getParam)
      .calledWith("/repo/nhs-environment/user-input/repo-dev-list")
      .mockResolvedValue(apiKeysStringList);

    when(initializeConfig).calledWith().mockReturnValue({
      nhsEnvironment: "nhs-environment",
      isStrictEnvironment: false,
    });
  });

  afterEach(() => jest.resetAllMocks());

  it("should create new user-api-key ssm parameter for a key that does not exist", async () => {
    when(getParamsByPath)
      .calledWith("/repo/nhs-environment/user-input/api-keys/")
      .mockResolvedValue([
        "/repo/nhs-environment/user-input/api-keys/service1/api-key-user/rob.deniro",
        "/repo/nhs-environment/user-input/api-keys/service2/api-key-user/joe.pesci",
      ]);

    when(h.convertUserListToUserListParamArray)
      .calledWith(usersAsArrayList)
      .mockReturnValue([
        "/repo/nhs-environment/user-input/api-keys/service1/api-key-user/rob.deniro",
        "/repo/nhs-environment/user-input/api-keys/service2/api-key-user/joe.pesci",
        "/repo/nhs-environment/user-input/api-keys/service2/api-key-user/al.pacino1",
      ]);

    await generateApiKeys(ssmPath, false);

    expect(getParam).toHaveBeenCalledWith(
      "/repo/nhs-environment/user-input/repo-dev-list"
    );
    expect(getParamsByPath).toHaveBeenCalledWith(
      "/repo/nhs-environment/user-input/api-keys/"
    );

    expect(generateApiKey).toHaveBeenCalledWith(
      "/repo/nhs-environment/user-input/api-keys/service2/api-key-user/al.pacino1"
    );
    expect(generateApiKey).toHaveBeenCalledTimes(1);
    expect(deleteApiKey).not.toHaveBeenCalled();

    expect(restartServices).toHaveBeenCalledWith([
      "/repo/nhs-environment/user-input/api-keys/service2/api-key-user/al.pacino1",
    ]);
  });

  it("should not create new user-api-key ssm parameter for a key that already exists", async () => {
    when(getParamsByPath)
      .calledWith("/repo/nhs-environment/user-input/api-keys/")
      .mockResolvedValue([
        "/repo/nhs-environment/user-input/api-keys/service1/api-key-user/rob.deniro",
      ]);

    when(h.convertUserListToUserListParamArray)
      .calledWith(usersAsArrayList)
      .mockReturnValue([
        "/repo/nhs-environment/user-input/api-keys/service1/api-key-user/rob.deniro",
      ]);

    await generateApiKeys(ssmPath, false);

    expect(getParam).toHaveBeenCalledWith(
      "/repo/nhs-environment/user-input/repo-dev-list"
    );

    expect(generateApiKey).not.toHaveBeenCalled();
    expect(deleteApiKey).not.toHaveBeenCalled();
    expect(restartServices).toHaveBeenCalledWith([]);
  });

  it("should delete user-api-key ssm parameter for a key that does not exist as expected user", async () => {
    const unexpectedUser =
      "/repo/nhs-environment/user-input/api-keys/service2/api-key-user/unexpected-user";
    when(getParamsByPath)
      .calledWith("/repo/nhs-environment/user-input/api-keys/")
      .mockResolvedValue([
        "/repo/nhs-environment/user-input/api-keys/service1/api-key-user/rob.deniro",
        "/repo/nhs-environment/user-input/api-keys/service2/api-key-user/joe.pesci",
        unexpectedUser,
      ]);

    when(h.convertUserListToUserListParamArray)
      .calledWith(usersAsArrayList)
      .mockReturnValue([
        "/repo/nhs-environment/user-input/api-keys/service1/api-key-user/rob.deniro",
        "/repo/nhs-environment/user-input/api-keys/service2/api-key-user/joe.pesci",
      ]);

    await generateApiKeys(ssmPath, false);

    expect(getParam).toHaveBeenCalledWith(
      "/repo/nhs-environment/user-input/repo-dev-list"
    );
    expect(getParamsByPath).toHaveBeenCalledWith(
      "/repo/nhs-environment/user-input/api-keys/"
    );

    expect(generateApiKey).not.toHaveBeenCalled();

    expect(deleteApiKey).toHaveBeenCalledTimes(1);
    expect(deleteApiKey).toHaveBeenCalledWith(unexpectedUser);

    expect(restartServices).toHaveBeenCalledWith([unexpectedUser]);
  });

  it("should both delete and generate user-api-keys ", async () => {
    const unexpectedUser =
      "/repo/nhs-environment/user-input/api-keys/service2/api-key-user/unexpected-user";
    const expectedUser =
      "/repo/nhs-environment/user-input/api-keys/service2/api-key-user/expected-user";

    when(getParamsByPath)
      .calledWith("/repo/nhs-environment/user-input/api-keys/")
      .mockResolvedValue([
        "/repo/nhs-environment/user-input/api-keys/service1/api-key-user/rob.deniro",
        "/repo/nhs-environment/user-input/api-keys/service2/api-key-user/joe.pesci",
        unexpectedUser,
      ]);

    when(h.convertUserListToUserListParamArray)
      .calledWith(usersAsArrayList)
      .mockReturnValue([
        "/repo/nhs-environment/user-input/api-keys/service1/api-key-user/rob.deniro",
        "/repo/nhs-environment/user-input/api-keys/service2/api-key-user/joe.pesci",
        expectedUser,
      ]);

    await generateApiKeys(ssmPath, false);

    expect(getParam).toHaveBeenCalledWith(
      "/repo/nhs-environment/user-input/repo-dev-list"
    );
    expect(getParamsByPath).toHaveBeenCalledWith(
      "/repo/nhs-environment/user-input/api-keys/"
    );

    expect(generateApiKey).toHaveBeenCalledWith(expectedUser);
    expect(generateApiKey).toHaveBeenCalledTimes(1);

    expect(deleteApiKey).toHaveBeenCalledTimes(1);
    expect(deleteApiKey).toHaveBeenCalledWith(unexpectedUser);

    expect(restartServices).toHaveBeenCalledWith([
      expectedUser,
      unexpectedUser,
    ]);
  });

  it("should not process service api keys", async () => {
    const serviceApiKey =
      "/repo/nhs-environment/user-input/api-keys/service2/service-api";

    when(getParamsByPath)
      .calledWith("/repo/nhs-environment/user-input/api-keys/")
      .mockResolvedValue([
        "/repo/nhs-environment/user-input/api-keys/service1/api-key-user/rob.deniro",
        "/repo/nhs-environment/user-input/api-keys/service2/api-key-user/joe.pesci",
        "/repo/nhs-environment/user-input/api-keys/service2/api-key-user/unexpected-user",
        serviceApiKey,
      ]);

    when(h.convertUserListToUserListParamArray)
      .calledWith(usersAsArrayList)
      .mockReturnValue([
        "/repo/nhs-environment/user-input/api-keys/service1/api-key-user/rob.deniro",
        "/repo/nhs-environment/user-input/api-keys/service2/api-key-user/joe.pesci",
        "/repo/nhs-environment/user-input/api-keys/service2/api-key-user/expected-user",
      ]);

    await generateApiKeys(ssmPath, false);

    expect(generateApiKey).not.toHaveBeenCalledWith(serviceApiKey);
    expect(deleteApiKey).not.toHaveBeenCalledWith(serviceApiKey);
    expect(restartServices).toHaveBeenCalledWith(
      expect.not.arrayContaining([serviceApiKey])
    );
  });

  it("should throw and error when ssm has no value", async () => {
    when(getParam).calledWith("repo-dev-empty-list").mockResolvedValue(null);

    await expect(
      generateApiKeys("repo-dev-empty-list", false)
    ).rejects.toEqual(new Error("Unable to retrieve list of api keys"));

    expect(generateApiKey).not.toHaveBeenCalled();
    expect(deleteApiKey).not.toHaveBeenCalled();
    expect(restartServices).not.toHaveBeenCalled();
  });
});
