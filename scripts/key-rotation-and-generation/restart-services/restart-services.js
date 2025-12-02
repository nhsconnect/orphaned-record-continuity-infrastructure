import {initializeConfig} from "../config"
import {restartECS} from "../aws-clients/ecs-client"
import {ClusterNotFoundException} from "@aws-sdk/client-ecs"


export const restartServices = async (apiKeys) => {
  let servicesToRestart = []
  for (const key of apiKeys) {
    const services = key.split(`/repo/${initializeConfig().nhsEnvironment}/user-input/api-keys/`)[1];
    const [ producerService, consumerService ] = services.split('/');
    addToServicesToRestart(servicesToRestart, producerService);

    if(consumerService !== 'api-key-user' && consumerService !== 'e2e-test' ){
      addToServicesToRestart(servicesToRestart, consumerService);
    }
  }

  for (const service of servicesToRestart) {
    try {
      await restartECS(service);
    } catch (e) {
      if (e.name === 'ClusterNotFoundException') {
        console.log(`Unable to restart cluster. Cluster not found for service ${service}`)
      } else {
        console.log('throwing error')
        throw e
      }
    }
  }
};

function addToServicesToRestart(servicesToRestart, serviceName) {
  if (!servicesToRestart.includes(serviceName)) {
    servicesToRestart.push(serviceName);
  }
}
