import { useContract, useContractEvents } from "@thirdweb-dev/react";

const useContractEvents = (filter) => {
  const { contract } = useContract("0x0777E4C556b76143349b81D86EAc8D36b7efB58E");
  // You can get a specific event
  const { data: event } = useContractEvents(
    contract, 
    filter,
    { 
      queryFilter: {
        fromBlock: 0, // Events starting from this block
        toBlock: "latest", // Events ending at this block
        order: "asc", // Order of events ("asc" or "desc")
      },
      subscribe: true, // Subscribe to new events
    },
  )
  
  return [event.data];
};

export default useContractEvents;