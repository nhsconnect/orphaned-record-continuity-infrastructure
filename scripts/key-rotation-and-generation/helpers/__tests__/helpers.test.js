import { convertUserListToUserListParamArray } from "../";
import { when } from "jest-when";
import { initializeConfig } from "../../config";
import { convertStringListToArray } from '../';

jest.mock("../../config");

describe("convertUserListToUserListParamArray", () => {
  it("should create user api key for each service in a non strict environment", () => {
    when(initializeConfig).calledWith().mockReturnValue({
      nhsEnvironment: "dev",
      isStrictEnvironment: false,
    });
    const result = convertUserListToUserListParamArray([
      "michael.stone",
      "will.smith",
    ]);

    expect(result).toEqual(
      expect.arrayContaining([
        "/repo/dev/user-input/api-keys/ehr-out-service/api-key-user/michael.stone",
        "/repo/dev/user-input/api-keys/ehr-repo/api-key-user/michael.stone",
        "/repo/dev/user-input/api-keys/ehr-out-service/api-key-user/will.smith",
        "/repo/dev/user-input/api-keys/ehr-repo/api-key-user/will.smith",
        "/repo/dev/user-input/api-keys/gp2gp-messenger/api-key-user/will.smith",
        "/repo/dev/user-input/api-keys/gp2gp-messenger/api-key-user/michael.stone",
      ])
    );
  });

  it("should create user api key for ehr-repo service only in a strict environment, the theory being it is locking down access to live patient EHR see PRMT-2186", () => {
    when(initializeConfig).calledWith().mockReturnValue({
      nhsEnvironment: "pre-prod",
      isStrictEnvironment: true,
    });
    const result = convertUserListToUserListParamArray([
      "michael.stone",
      "will.smith",
    ]);

    expect(result).toEqual(
      expect.arrayContaining([
        "/repo/pre-prod/user-input/api-keys/ehr-repo/api-key-user/michael.stone",
        "/repo/pre-prod/user-input/api-keys/ehr-repo/api-key-user/will.smith",
      ])
    );

    expect(result).toEqual(
      expect.not.arrayContaining([
        "/repo/dev/user-input/api-keys/ehr-out-service/api-key-user/michael.stone",
        "/repo/dev/user-input/api-keys/ehr-out-service/api-key-user/will.smith",
        "/repo/dev/user-input/api-keys/gp2gp-messenger/api-key-user/will.smith",
        "/repo/dev/user-input/api-keys/gp2gp-messenger/api-key-user/michael.stone",
      ])
    );
  });

  it("should throw error if expected api key list is empty", () => {
    expect(() => convertUserListToUserListParamArray([])).toThrow(
      "Expected user api key list is empty"
    );
  });
});

describe('convertStringListToArray', () => {
  it('should split comma separated list into array', () => {
    expect(convertStringListToArray('a,b,c')).toEqual(['a', 'b', 'c'])
  });

  it('should split newline separated list into array', () => {
    expect(convertStringListToArray('a\nb\nd')).toEqual(['a', 'b', 'd'])
  });

  it('should split comma and newline separated list into array', () => {
    expect(convertStringListToArray('c,\nb,\ne')).toEqual(['c', 'b', 'e'])
  });
})