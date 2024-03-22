// Updated setup with caps, running sums, payout adjustment including initial circulation, and burn mechanism
let epochs = 888;
let growthRate = 1.04;
let users = 10;
let postsCap = 11111; // Cap on the number of posts per epoch
let votesCap = postsCap * 10 + 1; // Cap on the number of votes per epoch
let posts = 100;
let votes = 1000;
let baseCostPerVote = 0.01;
let baseCostPerSubmission = 0.03;
let baseTotalRewardPool = 121.68;
let activityFactor = 0.25;
let founderFundPercentage = 0.011; // 1.1% to discretionary founder fund
let reservoir = 33333; // Initial reservoir size
let totalFounderFund = 0; // Running sum for the founder's fund
let totalCirculation = 22222; // Starting total circulation including initial condition
let totalSupply = 88888; // Initial total supply
let burnPercentage = 0.0; // Example: 3.3% of the recovered fees are burned each epoch

console.log("Epoch | Users | Posts | Votes | Cost Per Vote | Cost Per Submission | Estimated Recovery | Activity Factor | Reward Pool | Founder's Fund Contribution | Total Founder Fund | Reservoir | Total Circulation | Total Supply");

for (let epoch = 1; epoch <= epochs; epoch++) {
    let adjustedActivityFactor = Math.min(1, activityFactor * growthRate);

    // Enforce caps on posts and votes
    posts = Math.min(posts * growthRate, postsCap);
    votes = Math.min(votes * growthRate, votesCap);

    let costPerVote = baseCostPerVote * adjustedActivityFactor;
    let costPerSubmission = baseCostPerSubmission * adjustedActivityFactor;
    let excessPercentage = reservoir > 33333 ? (reservoir - 33333) / 33333 * 33.3 : 0;
    let totalRewardPool = Math.min((baseTotalRewardPool + baseTotalRewardPool * excessPercentage) * adjustedActivityFactor, reservoir);

    let recoveryVotes = votes * costPerVote;
    let recoveryPosts = posts * costPerSubmission;
    let estimatedRecovery = recoveryVotes + recoveryPosts;

    let burnAmount = estimatedRecovery * burnPercentage; // Calculate the burn amount for the epoch
    estimatedRecovery -= burnAmount; // Adjust the estimated recovery after burning
    totalSupply -= burnAmount; // Reduce the total supply by the burn amount

    let recoveryToProtocol = estimatedRecovery / 2;
    let foundersFundContribution = recoveryToProtocol * founderFundPercentage;
    

    // Update running sums and reservoir balance
    totalFounderFund += foundersFundContribution;
    totalCirculation += totalRewardPool;
    totalCirculation -= recoveryToProtocol;
    reservoir -= totalRewardPool;
    reservoir += recoveryToProtocol;

    console.log(`${epoch} | ${Math.round(users)} | ${Math.round(posts)} | ${Math.round(votes)} | ${costPerVote.toFixed(5)} NAIM | ${costPerSubmission.toFixed(5)} NAIM | ${estimatedRecovery.toFixed(2)} NAIM | ${adjustedActivityFactor.toFixed(2)} | ${totalRewardPool.toFixed(2)} NAIM | ${foundersFundContribution.toFixed(2)} NAIM | ${totalFounderFund.toFixed(2)} NAIM | ${reservoir.toFixed(2)} NAIM | ${totalCirculation.toFixed(2)} NAIM | ${totalSupply.toFixed(2)} NAIM`);

    users *= growthRate; // Update user growth
    activityFactor = adjustedActivityFactor; // Update activity factor for the next epoch
}

