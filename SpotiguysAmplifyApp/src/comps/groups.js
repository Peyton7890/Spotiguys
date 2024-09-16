import React, { useState, useEffect } from "react";
import "./App.css";
import "@aws-amplify/ui-react/styles.css";
import { API } from "aws-amplify";
import {
  Button,
  Flex,
  Heading,
  Text,
  TextField,
  View,
  withAuthenticator,
} from "@aws-amplify/ui-react";
import { listGroups } from "./graphql/queries";
import {
  createGroups as createGroupsMutation,
  deleteGroups as deleteGroupsMutation,
} from "../graphql/mutations";

const groups = () => {
  const [groups, setGroups] = useState([]);

  useEffect(() => {
    fetchGroups();
  }, []);

  async function fetchGroups() {
    const apiData = await API.graphql({ query: listGroups });
    const groupsFromAPI = apiData.data.listGroups.items;
    setGroups(groupsFromAPI);
  }

  async function createGroup(event) {
    event.preventDefault();
    const form = new FormData(event.target);
    const data = {
      name: form.get("name"),
    };
    await API.graphql({
      query: createGroupsMutation,
      variables: { input: data },
    });
    fetchGroups();
    event.target.reset();
  }

  async function deleteGroup({ id }) {
    const newGroup = groups.filter((note) => note.id !== id);
    setGroups(newGroup);
    await API.graphql({
      query: deleteGroupsMutation,
      variables: { input: { id } },
    });
  }

  return (
    <View className="App">
      <Heading level={1}>Groups</Heading>
      <View as="form" margin="3rem 0" onSubmit={createGroup}>
        <Flex direction="row" justifyContent="center">
          <TextField
            name="name"
            placeholder="Group Name"
            label="Note Name"
            labelHidden
            variation="quiet"
            required
          />
          <Button type="submit" variation="primary">
            Create Group
          </Button>
        </Flex>
      </View>
      <Heading level={2}>Current Notes</Heading>
      <View margin="3rem 0">
        {notes.map((note) => (
          <Flex
            key={note.id || note.name}
            direction="row"
            justifyContent="center"
            alignItems="center"
          >
            <Text as="strong" fontWeight={700}>
              {note.name}
            </Text>
            <Text as="span">{note.description}</Text>
            <Button variation="link" onClick={() => deleteNote(note)}>
              Delete note
            </Button>
          </Flex>
        ))}
      </View>
    </View>
  );
};

export default App;