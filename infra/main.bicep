@sys.allowed([
  'dev'
  'prod'
])
param environment string = 'dev'

param githubRepositoryBranch string = 'master'

param gitHubRepositoryUrl string = 'https://github.com/RylandDeGregory/Blog'

param location string = 'eastus2'

param staticWebAppName string = 'swa-blog-use2-${environment}'

param tags object = {}

resource staticWebApp 'Microsoft.Web/staticSites@2025-03-01' = {
  name: staticWebAppName
  location: location
  sku: {
    name: 'Free'
    tier: 'Free'
  }
  properties: {
    branch: githubRepositoryBranch
    buildProperties: {
      appLocation: '/'
      apiLocation: ''
      outputLocation: 'public'
    }
    enterpriseGradeCdnStatus: 'Disabled'
    repositoryUrl: gitHubRepositoryUrl
    stagingEnvironmentPolicy: 'Enabled'
  }
  tags: tags
}
