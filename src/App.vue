<template>
  <div id="app">
    <LandingPage />
    <AllSubmissions />
  </div>
</template>

<script>
import LandingPage from './components/LandingPage.vue';
import AllSubmissions from './components/AllSubmissions.vue';

export default {
  name: 'App',
  components: {
    LandingPage,
    AllSubmissions
  }
};
</script>
