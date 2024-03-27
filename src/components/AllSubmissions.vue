<template>
 <div class="all-submissions">
   <h2>All Submissions</h2>
   <table>
     <thead>
       <tr>
         <th>ID</th>
         <th>Title</th>
         <th>URI</th>
         <th>Votes</th>
         <th>Action</th>
       </tr>
     </thead>
     <tbody>
       <tr v-for="(link, index) in links" :key="index">
         <td>{{ link.id }}</td>
         <td>{{ link.title }}</td>
         <td>{{ link.uri }}</td>
         <td>{{ link.votes }}</td>
         <td>
           <button @click="upvoteLink(index)">Upvote</button>
         </td>
       </tr>
     </tbody>
   </table>
 </div>
</template>

<script>
import { contractInstance, initializeWeb3 } from './ethereum.mjs';

export default {
 data() {
   return {
     links: [],
   };
 },
 async created() {
   await initializeWeb3();
   await this.fetchLinks();
 },
 methods: {
   async fetchLinks() {
     const [ids, titles, uris] = await contractInstance.methods.getAllLinkSubmissions().call();
     const [_, votes] = await contractInstance.methods.getAllLinkVoteCounts().call();

     this.links = ids.map((id, index) => ({
       id,
       title: titles[index],
       uri: uris[index],
       votes: votes[index],
     }));
   },
   async upvoteLink(linkIndex) {
     const linkId = this.links[linkIndex].id;
     const accounts = await web3.eth.getAccounts();
     await contractInstance.methods.upvoteLink(linkId).send({ from: accounts[0], value: web3.utils.toWei('0.000010', 'ether') });
     await this.fetchLinks();
   },
 },
};
</script>

<style scoped>
.all-submissions {
 margin: 20px;
}

h2 {
 font-size: 24px;
 margin-bottom: 10px;
}

table {
 width: 100%;
 border-collapse: collapse;
}

th,
td {
 padding: 10px;
 text-align: left;
 border-bottom: 1px solid #ddd;
}

th {
 background-color: #f2f2f2;
}

button {
 padding: 5px 10px;
 background-color: #007bff;
 color: #fff;
 border: none;
 border-radius: 4px;
 cursor: pointer;
}
</style>