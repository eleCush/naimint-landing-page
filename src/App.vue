<template>
  <div id="app">
    <LandingPage />
  </div>
</template>

<script>
import LandingPage from './components/LandingPage.vue';

export default {
  name: 'App',
  mounted() {
   document.title = "NAIMINT: Shape the Future of Content"
  },
  components: {
    LandingPage
  }
};
</script>
