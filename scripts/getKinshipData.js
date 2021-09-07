const { extract } = require("./gen_files/results_kinship_drop_tickets.js");
const allAddresses = []; //with duplicates

const finalArray = [];
const fs = require("fs");
//const arrayif = [rawData];
for (let i = 0; i < extract().length; i++) {
  // console.log(extract()[i].owner);
  allAddresses.push(extract()[i].owner);
}
const uniqueAddresses = [...new Set(allAddresses)];
console.log(uniqueAddresses);

function User(address, gotchis) {
  this.address = address;
  this.id = 6;
  this.tickets = gotchis;
}

function find(array, item) {
  let occurences = 0;
  for (let j = 0; j < array.length; j++) {
    if (array[j] === item) {
      occurences++;
    }
  }
  return item, occurences;
}

function generate(addressArray) {
  var eachObj;
  for (let i = 0; i < uniqueAddresses.length; i++) {
    eachObj = new User(
      uniqueAddresses[i],
      find(addressArray, uniqueAddresses[i])
    );
    finalArray.push(eachObj);
  }
  fs.writeFile(
    "scripts/gen_files/finalKinshipList.js",
    JSON.stringify(finalArray, null, 4),
    (err) => {
      if (err) {
        console.error(err);
        return;
      }
    }
  );
  return finalArray;
}

//countTickets(allAddresses);
//console.log(find(allAddresses, "0x9cca9d2aad42623b068017da87a8689aa80b9e76"));
//console.log(generate(allAddresses));
