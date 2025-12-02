import {
  DeleteParameterCommand, GetParameterCommand,
  GetParametersByPathCommand, ListTagsForResourceCommand, PutParameterCommand, RemoveTagsFromResourceCommand
} from '@aws-sdk/client-ssm'
import {
  deleteApiKey,
  generateApiKey,
  getParam,
  getParamsByPath,
  getRotateApiKeyTag,
  removeRotateApiKeyTag,
  rotateApiKey
} from "../ssm-client"
import {ssmClient} from "../clients"
import {when} from "jest-when";
import randomstring from "randomstring";


jest.mock('@aws-sdk/client-ssm')
jest.mock("../clients")
jest.mock("randomstring")


describe('ssm-client', () => {

  const ssmPath = "/path"

  afterEach(() => jest.resetAllMocks())

  describe('getParam', () => {

    it('should return Name field from GetParameterCommand', async () => {
      const parameterName = "parameterName"
      const mockCommand = {command: "GetParameter"}
      const mockResponse = {Parameter: {Value: 'api-key-name'}}

      when(GetParameterCommand).calledWith({ Name: parameterName }).mockReturnValue(mockCommand)
      when(ssmClient.send).calledWith(mockCommand).mockReturnValue(mockResponse)

      const param = await getParam(parameterName)
      expect(param).toBe( 'api-key-name')
    })

    it('should return null if client throws ParameterNotFound exception', async () => {
      const parameterName = "parameterName"
      const mockCommand = {command: "GetParameter"}

      function MockParameterNotFoundException() {
        this.name = "ParameterNotFound";
        this.message = "Cluster not found";
      }

      when(GetParameterCommand).calledWith({ Name: parameterName }).mockReturnValue(mockCommand)
      when(ssmClient.send).calledWith(mockCommand).mockRejectedValue(new MockParameterNotFoundException())

      const param = await getParam(parameterName)
      expect(param).toBe( null)
    })

    it('should throw error for any other exception', async () => {
      const parameterName = "parameterName"
      const mockCommand = {command: "GetParameter"}

      when(GetParameterCommand).calledWith({ Name: parameterName }).mockReturnValue(mockCommand)
      when(ssmClient.send).calledWith(mockCommand).mockRejectedValue(new Error('unknown error'))

      await expect(getParam(parameterName)).rejects.toThrow( 'unknown error')
    })
  })

  describe('getParamsByPath', () => {
    it('should getParameters until NextToken is undefined', async () => {

      const mockCommand = {command: "firstCommand"}
      const mockSecondCommand = {command: "secondCommand"}

      const mockResponse = {NextToken: "NextTokenPresent", Parameters: [{Name: "a"}, {Name: "b"}, {Name: "c"}]}
      const mockSecondResponse = {NextToken: undefined, Parameters: [{Name: "d"}, {Name: "e"}, {Name: "f"}]}

      when(GetParametersByPathCommand)
        .calledWith({ Path: ssmPath, Recursive: true }).mockReturnValue(mockCommand)
        .calledWith({ Path: ssmPath, Recursive: true, NextToken: "NextTokenPresent" }).mockReturnValue(mockSecondCommand)
      when(ssmClient.send)
        .calledWith(mockCommand).mockResolvedValue(mockResponse)
        .calledWith(mockSecondCommand).mockResolvedValue(mockSecondResponse)

      const result = await getParamsByPath(ssmPath)
      expect(GetParametersByPathCommand).toHaveBeenCalledWith({ Path: ssmPath, Recursive: true })
      expect(GetParametersByPathCommand).toHaveBeenCalledWith({ Path: ssmPath, Recursive: true, NextToken: "NextTokenPresent" })
      expect(ssmClient.send).toBeCalledTimes(2)
      expect(result).toEqual(["a", "b", "c", "d", "e", "f"])
    })
  })

  describe('creating, updating and deleting api keys', () => {

    it('should create command with name for DeleteParameterCommand and send to client', async () => {
      const parameterName = "parameterName"
      const mockCommand = {command: "DeleteParameter"}

      when(DeleteParameterCommand).calledWith({Name: parameterName}).mockReturnValue(mockCommand)

      await deleteApiKey(parameterName)

      expect(DeleteParameterCommand).toHaveBeenCalledWith({Name: parameterName})
      expect(ssmClient.send).toHaveBeenCalledWith(mockCommand)
    })

    it('should create command with name for PutParameterCommand and send to client for generate', async () => {
      const parameterName = "parameterName"
      const mockCommand = {command: "DeleteParameter"}

      randomstring.generate.mockReturnValue("abc")

      when(PutParameterCommand).calledWith({ Name: parameterName, Type: 'SecureString', Value: "abc" }).mockReturnValue(mockCommand)

      await generateApiKey(parameterName)

      expect(PutParameterCommand).toHaveBeenCalledWith({ Name: parameterName, Type: 'SecureString', Value: "abc" })
      expect(ssmClient.send).toHaveBeenCalledWith(mockCommand)
    })

    it('should create command with name for PutParameterCommand and send to client for rotate', async () => {
      const parameterName = "parameterName"
      const mockCommand = {command: "PutParameter"}

      randomstring.generate.mockReturnValue("abc")

      when(PutParameterCommand).calledWith({ Name: parameterName, Type: 'SecureString', Value: "abc", Overwrite: true }).mockReturnValue(mockCommand)

      await rotateApiKey(parameterName)

      expect(PutParameterCommand).toHaveBeenCalledWith({ Name: parameterName, Type: 'SecureString', Value: "abc", Overwrite: true })
      expect(ssmClient.send).toHaveBeenCalledWith(mockCommand)
    })
  })

  describe('getRotateApiKeyTag', () => {

    it('should filter TagList for RotateApi key flag and return true if present', async () => {
      const ssmPath = "/ssm/path"
      const mockCommand = {command: "ListTags"}
      const mockResponse = {TagList: [{Key: 'RotateApiKey'}]}

      when(ListTagsForResourceCommand).calledWith({ ResourceId: ssmPath, ResourceType: 'Parameter' }).mockReturnValue(mockCommand)
      when(ssmClient.send).calledWith(mockCommand).mockReturnValue(mockResponse)

      const result = await getRotateApiKeyTag(ssmPath)
      expect(result).toBe( true)
    })

    it('should filter TagList for RotateApi key flag and return false if not present', async () => {
      const ssmPath = "/ssm/path"
      const mockCommand = {command: "ListTags"}
      const mockResponse = {TagList: [{Key: 'SomeOtherTag'}]}

      when(ListTagsForResourceCommand).calledWith({ ResourceId: ssmPath, ResourceType: 'Parameter' }).mockReturnValue(mockCommand)
      when(ssmClient.send).calledWith(mockCommand).mockReturnValue(mockResponse)

      const result = await getRotateApiKeyTag(ssmPath)
      expect(result).toBe( false)
    })
  })

  describe('removeRotateApiKeyTag', () => {

    it('should filter TagList for RotateApi key flag and return true if present', async () => {
      const ssmPath = "/ssm/path"
      const mockCommand = {command: "ListTags"}

      when(RemoveTagsFromResourceCommand).calledWith({ ResourceId: ssmPath, ResourceType: 'Parameter', TagKeys: ['RotateApiKey'] })
        .mockReturnValue(mockCommand)

      await removeRotateApiKeyTag(ssmPath)
      expect(RemoveTagsFromResourceCommand).toHaveBeenCalledWith({ ResourceId: ssmPath, ResourceType: 'Parameter', TagKeys: ['RotateApiKey'] })
      expect(ssmClient.send).toHaveBeenCalledWith(mockCommand)
    })
  })

})
