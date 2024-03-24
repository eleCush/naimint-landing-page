<template>
  <div class="landing-page">
    <div class="header">
      <h1>Welcome to NAIMINT</h1>
      <p>Sign up to stay updated on our platform's progress and be part of the community!</p>
    </div>
    <div class="form-container">
      <form @submit.prevent="submitForm" action="https://formspree.io/f/mzbnakev" method="POST">
        <div class="form-group">
          <input type="email" name="email" v-model="email" placeholder="Your email address" required>
        </div>
        <div class="form-group">
          <textarea name="interest" v-model="interest" placeholder="Why are you interested in NAIMINT?" required></textarea>
        </div>
        <button type="submit" class="glow-on-hover">Sign Up</button>
      </form>
    </div>
    <div class="wordpress-link">
      <a href="https://naimint.wordpress.com/2024/03/20/naimint-a-new-dawn-for-content-creators-and-consumers/" target="_blank">Read our introductory blog post</a>
    </div>
    <div class="wordpress-link">
      <a href="https://naimint.com/naimint-info-6.html" target="_blank">Read about the Naimint Tokenomics, Fixed Supply and Payout Epochs</a>
    </div>
  </div>
</template>

<script>
export default {
  data() {
    return {
      email: '',
      interest: ''
    };
  },
  methods: {
   async submitForm() {
  const formData = new FormData();
  formData.append('email', this.email);
  formData.append('interest', this.interest);

  try {
    const response = await fetch('https://formspree.io/f/mzbnakev', {
      method: 'POST',
      body: formData,
      headers: {
        'Accept': 'application/json',
      },
    });
    
    if (response.ok) {
      // Handle successful submission
      alert('Thank you for signing up!');
      // Reset form
      this.email = '';
      this.interest = '';
    } else {
      // Handle errors or unsuccessful submission
      alert('Submission failed. Please try again.');
    }
  } catch (error) {
    console.error('Error submitting form:', error);
    alert('An error occurred. Please try again.');
  }
}

  }
};
</script>

<style scoped>
.landing-page {
  background: linear-gradient(45deg, #ff5f6d, #ffc371, #32a852, #008cff);
  background-size: 400% 400%;
  animation: gradientAnimation 15s ease infinite;
  min-height: 100vh;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  color: #ffffff;
  font-family: 'Roboto', sans-serif;
}

@keyframes gradientAnimation {
  0% {
    background-position: 0% 50%;
  }
  50% {
    background-position: 100% 50%;
  }
  100% {
    background-position: 0% 50%;
  }
}

.header {
  text-align: center;
  margin-bottom: 40px;
}

h1 {
  font-size: 48px;
  font-weight: bold;
  margin-bottom: 20px;
  color: #ffffff;
  text-shadow: 2px 2px 4px rgba(0, 0, 0, 0.5);
}

p {
  font-size: 24px;
  color: #ffffff;
  opacity: 0.8;
}

.form-container {
  background-color: rgba(44, 47, 63, 0.8);
  padding: 40px;
  border-radius: 10px;
  box-shadow: 0 4px 6px rgba(0, 0, 0, 0.1);
}

.form-group {
  margin-bottom: 20px;
}

input,
textarea {
  width: 100%;
  padding: 10px;
  font-size: 18px;
  border: none;
  border-radius: 5px;
  background-color: rgba(60, 63, 79, 0.8);
  color: #ffffff;
}

textarea {
  height: 120px;
}

.glow-on-hover {
  display: block;
  width: 100%;
  padding: 12px;
  font-size: 20px;
  font-weight: bold;
  text-transform: uppercase;
  color: #ffffff;
  background-color: rgba(255, 215, 0, 0.8);
  border: none;
  border-radius: 5px;
  cursor: pointer;
  transition: all 0.3s;
}

.glow-on-hover:hover {
  background-color: rgba(255, 223, 64, 0.8);
  box-shadow: 0 0 10px rgba(255, 215, 0, 0.8);
}

.wordpress-link {
  margin-top: 40px;
}

.wordpress-link a {
  color: #ffffff;
  text-decoration: none;
  font-size: 20px;
  transition: color 0.3s;
}

.wordpress-link a:hover {
  color: #ffd700;
}
</style>
