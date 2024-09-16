import logo from './assets/logo.png';
import './App.css';
import {Amplify, API} from 'aws-amplify';
import {React, useState, useEffect} from 'react';
import axios from 'axios';
import {
  Button,
  Card,
  Flex,
  Heading,
  Text,
  TextField,
  View,
  Grid,
  Collection,
  withAuthenticator,
  Loader,
  Alert,
} from "@aws-amplify/ui-react";
import '@aws-amplify/ui-react/styles.css';
import { listGroups, listGroupMembers, getGroupMembers } from './graphql/queries';
import {
  createGroups as createGroupsMutation,
  deleteGroups as deleteGroupMutation,
  deleteGroupMembers as deleteGroupMemberMutation,
  createGroupMembers as createMembersMutation,
} from "./graphql/mutations";
import config from './aws-exports';


Amplify.configure(config);


function App({ signOut }) {

  const [groups, setGroups] = useState([]);
  const [groupMembers, setGroupMembers] = useState([]);
  const [loadingProcess, setLoadingProcess] = useState(false);
  const [processMessage, setProcessMessage] = useState("");
  const [loadingPlaylist, setLoadingPlaylist] = useState(false);
  const [playlistMessage, setPlaylistMessage] = useState("");

  const CLIENT_ID = "18f485d7a7144f5aaff8be68dfa5d40e"
  const REDIRECT_URI = "https://spotiguys.tk"
  const AUTH_ENDPOINT = "https://accounts.spotify.com/authorize"
  const RESPONSE_TYPE = "token"
  const SCOPE = "user-read-private%20playlist-read-private%20playlist-modify-private%20playlist-modify-public"

  const [token, setToken] = useState("")
  const [userId, setUserId] = useState("")
  const [userName, setUserName] = useState("")

  useEffect(() => {
    const hash = window.location.hash
    let token = window.localStorage.getItem("token")
    console.log(hash)

    if (!token && hash) {
        token = hash.substring(1).split("&").find(elem => elem.startsWith("access_token")).split("=")[1]

        window.location.hash = ""
        window.localStorage.setItem("token", token)
    }

    setToken(token)

  }, [])

  const logout = () => {
    setToken("")
    window.localStorage.removeItem("token")
  }

  const getInfo = async (e) => {
    e.preventDefault();
    const {data} = await axios.get("https://api.spotify.com/v1/me?access_token=" + token);
    console.log(data["display_name"]);

    setUserId(data["id"]);
    setUserName(data["display_name"]);

    fetchGroups();
    fetchGroupMembers();

    callBack();

  }

  async function createGroup(event) {
    event.preventDefault();
    const form = new FormData(event.target);
    const data = {
      Name: form.get("grp_name"),
      Owner_key: token,
      Owner_id: userId
    };
    await API.graphql({
      query: createGroupsMutation,
      variables: { input: data },
    });
    fetchGroups();

    event.target.reset();

  }

  async function fetchGroups() {
    const apiData = await API.graphql({ query: listGroups });
    const groupsFromAPI = apiData.data.listGroups.items;
    setGroups(groupsFromAPI);
  }

  async function fetchGroupMembers() {
    const apiData = await API.graphql({ query: listGroupMembers });
    console.log("HERE - ", groupMembers);
    const groupMembersFromAPI = apiData.data.listGroupMembers.items;
    setGroupMembers(groupMembersFromAPI);
  }

  async function deleteGroup({ id }){
    const newGroups = groups.filter((group) => group.id !== id);
    setGroups(newGroups);
    await API.graphql({
      query: deleteGroupMutation,
      variables: { input: { id } },
    });
  }

  async function deleteGroupMembers({ id }){
    const newGroupMember = groupMembers.filter((member) => member.id !== id);
    setGroupMembers(newGroupMember);
    await API.graphql({
      query: deleteGroupMemberMutation,
      variables: { input: { id } },
    });
  }

  async function joingGroup({ id }){
    const newGroups = groups.filter((group) => group.id === id);
    console.log("HERE - 2", newGroups);
    const groupData = newGroups[0];
    const data = {
      Member_id: userId,
      Member_key: token,
      Member_name: userName,
      groupMembersGroupsId: groupData["id"]
    };
    await API.graphql({
      query: createMembersMutation,
      variables: { input: data },
    });
    fetchGroupMembers();
    console.log(groupMembers);
  }

  async function getMembers({ id }){
    const members = groupMembers.filter((member) => member.Groups.id === id);
    console.log("THERE", members);
    return members;
  }

  const callBack = async (e) => {
    const {data} = await axios.get(`https://api.spotiguys.tk/callback`,{
      method: 'GET',
      headers: {
        'Content-Type': 'application/json'
      },
      params: {
        'access_token': token
      }

    })
    console.log(data)
  }

  async function kinesisProducer(id){
    setLoadingProcess(true);
    const data = await axios.get(`https://api.spotiguys.tk/create-playlist`,{
      method: 'GET',
      headers: {
        'Content-Type': 'application/json'
      },
      params: {
        'id': id
      }

    }).then((result) => { 
      setLoadingProcess(false);
      setProcessMessage("Your playlist data has been procesed");
      
      console.log(result);
    })
  }

  async function createPlaylist(key){
    setLoadingPlaylist(true);
    const data = await axios.get(`https://api.spotiguys.tk/post-playlist`,{
      method: 'GET',
      headers: {
        'Content-Type': 'application/json'
      },
      params: {
        'access_token': key
      }

    }).then((result) => {
      setLoadingPlaylist(false);
      setPlaylistMessage("Your playlist has been created");
      console.log(result);
    })
  }
  
  
  return (
    <div className="App">
            <header className="App-header">
                <img class="logo_image" src={logo} alt="Spotiguys"></img>
                {!token ?
                    <div>
                    <a color='aliceblue' href={`${AUTH_ENDPOINT}?client_id=${CLIENT_ID}&redirect_uri=${REDIRECT_URI}&response_type=${RESPONSE_TYPE}&scope=${SCOPE}`}>Login
                        to Spotify</a>
                     </div>
                    : <Button onClick={logout}>Logout</Button>}
                {!userName ?
                <a></a>
                : <a>Hello {userName}</a>}
                <Button variation='primary' onClick={getInfo}>Fetch User Data</Button>
                <View margin="3rem 0">
                  <Heading color="aliceblue" level={1}>Groups</Heading>
                  <View as="form" margin="3rem 0" onSubmit={createGroup}>
                    <Flex direction="row" justifyContent="center">
                      <TextField
                        name="grp_name"
                        placeholder="Group Name"
                        label="Group Name"
                        labelHidden
                        variation="quiet"
                        required
                      />
                      <Button type="submit" variation="primary">
                        Create Group
                      </Button>
                    </Flex>
                  </View>
                  <Heading color="aliceblue" level={2}>Current Groups</Heading>
                  <View margin="3rem 0">
                    <Collection
                      items={groups}
                      type="list"
                      direction="row"
                      gap="20px"
                      wrap="nowrap"
                    >
                      {(item, index) => (
                        <Card
                          key={index}
                          borderRadius="medium"
                          maxWidth="20rem"
                          variation="outlined"
                        >
                          <View padding="xs">
                            <Heading padding="medium">{item.Name}</Heading>
                            <Collection
                              items={groupMembers}
                              type="list"
                              direction="column"
                              wrap="nowrap"
                              gap="1px"
                              padding="xs"
                            >
                              {(member, ind) => (
                                <Grid
                                  key={ind}
                                >
                                  <View as="div" display="inline-flex" borderRadius="10px">
                                    <Text padding="xs">
                                      {member.Member_name}
                                    </Text>
                                    <Button left="0.5rem" padding="xs" variation="menu" onClick={() => deleteGroupMembers(member)}>Remove User</Button>
                                  </View>
                                </Grid>
                              )}
                            </Collection>
                            <Button marginTop="xxs" variation="primary" onClick={() => joingGroup(item)} isFullWidth>Join Group</Button>
                            <Button marginTop="xxs" variation="primary" onClick={() => deleteGroup(item)} isFullWidth>Delete group</Button>
                            <Button marginTop="xxs" variation='primary' onClick={() => kinesisProducer(item.Owner_id)} isFullWidth>Process Data</Button>
                            {loadingProcess ? <Loader/> : <Alert variation='success' isDismissible={true} hasIcon={true} heading="Success">{processMessage}</Alert>}
                            <Button marginTop="xxs" variation='primary' onClick={() => createPlaylist(item.Owner_key)} isFullWidth>Create Playlist</Button>
                            {loadingPlaylist ? <Loader/> : <Alert variation='success' isDismissible={true} hasIcon={true} heading="Success">{playlistMessage}</Alert>}
                          </View>
                        </Card>
                      )}
                    </Collection>
                  </View>

                  {/* <Button onClick={fetchGroupMembers}>Fetch Group Members</Button>
                  <Button onClick={fetchGroups}>Fetch Group Data</Button> */}


                </View>
            </header>
        </div>
  );
}

export default App;
