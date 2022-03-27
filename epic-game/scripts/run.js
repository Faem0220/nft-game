const main = async () => {
  const gameContractFactory = await hre.ethers.getContractFactory('MyEpicGame');
  const gameContract = await gameContractFactory.deploy(
      ["SmartTv", "Smartphone", "Laptop"],  
      ["QmNwkWVaJoUKqbnCVy9cYJkr3kaHm5tiMvTWWHikRMFRgh", 
      "QmcQq4oRzxZh2zm4g1JGKdGKkPzEubsvnN2teA4bhdqSYw", 
      "QmT7UjHeXyxNMtLydv93EdTP4qU7qyWgFFhVJaSvA6VWEN"],
      [300, 100, 200],                   
      [10, 20, 50],                       
      "Datacenter",
      "QmVcasWHvF3B3bcrSh5LLTei2dEjBth1Yu6HDbDi2rPzs7",
      10000,
      50
    );
  await gameContract.deployed();
  console.log("Contract deployed to:", gameContract.address);

  let txn = await gameContract.mint(1);
  await txn.wait()
  txn = await gameContract.mint(2);
  await txn.wait()
  let allPlayers = await gameContract.getAllPlayers()
  console.log(await allPlayers)
  
};

const runMain = async () => {
  try {
    await main();
    process.exit(0);
  } 
  catch (error) {
    console.log(error);
    process.exit(1);
  }
};
runMain();