import { SdkType, getSdk } from "./generated/apollo";
import { setContext } from '@apollo/client/link/context';

import { ApolloClient, InMemoryCache, createHttpLink, from } from "@apollo/client";
import { onError } from "@apollo/client/link/error";
import { store } from './mobx/Global.store'

const httpLink = createHttpLink({
  uri: process.env.REACT_APP_APOLLO_CLIENT_URI,
});

const authLink = setContext((_, { headers }) => {
  let token = localStorage.getItem('access_token');
  if (token) {
    token = JSON.parse(token);
  }

  return {
    headers: {
      ...headers,
      Authorization: token ? `Bearer ${token}` : "",
      'workspace-id': store?.currWorkspaceId
    }
  }
});


const errorLink = onError(({ graphQLErrors, networkError }) => {
  if (graphQLErrors) {
    for (let err of graphQLErrors) {
      switch (err.extensions.code) {
        // Apollo Server sets code to UNAUTHENTICATED
        // when an AuthenticationError is thrown in a resolver
        case 'UNAUTHENTICATED':
          window.location.href = '/login'
          break;
        
      }
    }
  }
    

  if (networkError) console.log(`[Network error]: ${networkError}`);
});


export const client = new ApolloClient({
  // uri: process.env.REACT_APP_APOLLO_CLIENT_URI,
  cache: new InMemoryCache(),
  // link: authLink,
  link: from([authLink, errorLink, httpLink, ]),
  defaultOptions: {
    watchQuery: {
      fetchPolicy: 'network-only',
    }
  },
  
});


export const sdk: SdkType = getSdk(client);