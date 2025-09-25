import randomstring from "randomstring";
import {ssmClient as client} from "./clients"
import {
  DeleteParameterCommand,
  GetParameterCommand,
  GetParametersByPathCommand,
  ListTagsForResourceCommand,
  PutParameterCommand,
  RemoveTagsFromResourceCommand
} from '@aws-sdk/client-ssm'

export const getParam = async (parameterName) => {
  const command = new GetParameterCommand({ Name: parameterName });
  try {
    const ssmParameter = await client.send(command);
    return ssmParameter.Parameter.Value;
  } catch (err) {
    if(err.name === 'ParameterNotFound') {
      console.log(`ParameterNotFound - ${parameterName}`)
      return null;
    }
    throw err;
  }
};

export const getParamsByPath = async (ssmPath) => {
  console.log(`Getting first set of parameters for ssm path ${ssmPath}`)
  const command = new GetParametersByPathCommand({ Path: ssmPath, Recursive: true });
  const response = await client.send(command);

  let results = response.Parameters.map(param => param.Name)
  let nextToken = response.NextToken

  while (nextToken) {
    console.log(`NextToken is present getting next set of parameters for ssm path ${ssmPath} starting from result ${results.length}`)
    const command = new GetParametersByPathCommand({ Path: ssmPath, Recursive: true, NextToken: nextToken });
    const response = await client.send(command);
    results = results.concat(response.Parameters.map(param => param.Name))
    nextToken = response.NextToken
  }
  console.log(`Total ${results.length} parameters found for ${ssmPath}`)

  return results
};

export const generateApiKey = async (parameterName) => {
  const keyValue = randomstring.generate();
  const command = new PutParameterCommand({ Name: parameterName, Type: 'SecureString', Value: keyValue });
  await client.send(command);

  console.log(`${parameterName} API Key has been generated`)
}

export const rotateApiKey = async (parameterName) => {
  const keyValue = randomstring.generate();
  const command = new PutParameterCommand({ Name: parameterName, Type: 'SecureString', Value: keyValue, Overwrite: true });
  await client.send(command);

  console.log(`${parameterName} API Key has been rotated`)
}

export const deleteApiKey = async (parameterName) => {
  const command = new DeleteParameterCommand({Name: parameterName});
  await client.send(command);

  console.log(`${parameterName} API Key has been deleted`)
}

export const getRotateApiKeyTag = async (ssmPath) => {
  const command = new ListTagsForResourceCommand({ ResourceId: ssmPath, ResourceType: 'Parameter' });
  const response = await client.send(command);
  const rotateApiKeyTag = response.TagList.filter(tag => tag.Key === 'RotateApiKey');
  return rotateApiKeyTag.length !== 0;
};

export const removeRotateApiKeyTag = async (ssmPath) => {
  const command = new RemoveTagsFromResourceCommand({ ResourceId: ssmPath, ResourceType: 'Parameter', TagKeys: ['RotateApiKey'] });
  await client.send(command);
};
