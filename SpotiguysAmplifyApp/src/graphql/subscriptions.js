/* eslint-disable */
// this is an auto generated file. This will be overwritten

export const onCreateGroupMembers = /* GraphQL */ `
  subscription OnCreateGroupMembers(
    $filter: ModelSubscriptionGroupMembersFilterInput
  ) {
    onCreateGroupMembers(filter: $filter) {
      id
      Member_id
      Member_key
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
export const onUpdateGroupMembers = /* GraphQL */ `
  subscription OnUpdateGroupMembers(
    $filter: ModelSubscriptionGroupMembersFilterInput
  ) {
    onUpdateGroupMembers(filter: $filter) {
      id
      Member_id
      Member_key
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
export const onDeleteGroupMembers = /* GraphQL */ `
  subscription OnDeleteGroupMembers(
    $filter: ModelSubscriptionGroupMembersFilterInput
  ) {
    onDeleteGroupMembers(filter: $filter) {
      id
      Member_id
      Member_key
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
export const onCreateGroups = /* GraphQL */ `
  subscription OnCreateGroups($filter: ModelSubscriptionGroupsFilterInput) {
    onCreateGroups(filter: $filter) {
      id
      Name
      Owner_key
      Owner_id
      createdAt
      updatedAt
    }
  }
`;
export const onUpdateGroups = /* GraphQL */ `
  subscription OnUpdateGroups($filter: ModelSubscriptionGroupsFilterInput) {
    onUpdateGroups(filter: $filter) {
      id
      Name
      Owner_key
      Owner_id
      createdAt
      updatedAt
    }
  }
`;
export const onDeleteGroups = /* GraphQL */ `
  subscription OnDeleteGroups($filter: ModelSubscriptionGroupsFilterInput) {
    onDeleteGroups(filter: $filter) {
      id
      Name
      Owner_key
      Owner_id
      createdAt
      updatedAt
    }
  }
`;
