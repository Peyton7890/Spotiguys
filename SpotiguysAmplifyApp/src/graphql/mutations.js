/* eslint-disable */
// this is an auto generated file. This will be overwritten

export const createGroupMembers = /* GraphQL */ `
  mutation CreateGroupMembers(
    $input: CreateGroupMembersInput!
    $condition: ModelGroupMembersConditionInput
  ) {
    createGroupMembers(input: $input, condition: $condition) {
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
export const updateGroupMembers = /* GraphQL */ `
  mutation UpdateGroupMembers(
    $input: UpdateGroupMembersInput!
    $condition: ModelGroupMembersConditionInput
  ) {
    updateGroupMembers(input: $input, condition: $condition) {
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
export const deleteGroupMembers = /* GraphQL */ `
  mutation DeleteGroupMembers(
    $input: DeleteGroupMembersInput!
    $condition: ModelGroupMembersConditionInput
  ) {
    deleteGroupMembers(input: $input, condition: $condition) {
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
export const createGroups = /* GraphQL */ `
  mutation CreateGroups(
    $input: CreateGroupsInput!
    $condition: ModelGroupsConditionInput
  ) {
    createGroups(input: $input, condition: $condition) {
      id
      Name
      Owner_key
      Owner_id
      createdAt
      updatedAt
    }
  }
`;
export const updateGroups = /* GraphQL */ `
  mutation UpdateGroups(
    $input: UpdateGroupsInput!
    $condition: ModelGroupsConditionInput
  ) {
    updateGroups(input: $input, condition: $condition) {
      id
      Name
      Owner_key
      Owner_id
      createdAt
      updatedAt
    }
  }
`;
export const deleteGroups = /* GraphQL */ `
  mutation DeleteGroups(
    $input: DeleteGroupsInput!
    $condition: ModelGroupsConditionInput
  ) {
    deleteGroups(input: $input, condition: $condition) {
      id
      Name
      Owner_key
      Owner_id
      createdAt
      updatedAt
    }
  }
`;
