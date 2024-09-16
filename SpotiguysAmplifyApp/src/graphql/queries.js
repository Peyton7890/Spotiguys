/* eslint-disable */
// this is an auto generated file. This will be overwritten

export const getGroupMembers = /* GraphQL */ `
  query GetGroupMembers($id: ID!) {
    getGroupMembers(id: $id) {
      id
      Member_id
      Member_key
      Member_name
      Groups {
        id
        Name
        Owner_key
        Owner_id
        createdAt
        updatedAt
      }
      createdAt
      updatedAt
      groupMembersGroupsId
    }
  }
`;
export const listGroupMembers = /* GraphQL */ `
  query ListGroupMembers(
    $filter: ModelGroupMembersFilterInput
    $limit: Int
    $nextToken: String
  ) {
    listGroupMembers(filter: $filter, limit: $limit, nextToken: $nextToken) {
      items {
        id
        Member_id
        Member_key
        Member_name
        Groups {
          id
          Name
          Owner_key
          Owner_id
          createdAt
          updatedAt
        }
        createdAt
        updatedAt
        groupMembersGroupsId
      }
      nextToken
    }
  }
`;
export const getGroups = /* GraphQL */ `
  query GetGroups($id: ID!) {
    getGroups(id: $id) {
      id
      Name
      Owner_key
      Owner_id
      createdAt
      updatedAt
    }
  }
`;
export const listGroups = /* GraphQL */ `
  query ListGroups(
    $filter: ModelGroupsFilterInput
    $limit: Int
    $nextToken: String
  ) {
    listGroups(filter: $filter, limit: $limit, nextToken: $nextToken) {
      items {
        id
        Name
        Owner_key
        Owner_id
        createdAt
        updatedAt
      }
      nextToken
    }
  }
`;
