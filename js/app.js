const tableElem = document.getElementById("table-body");
const candidateOptions = document.getElementById("candidate-options");
const voteForm = document.getElementById("vote-form");

var proposals = [];
var isChairparson = false;
var myAddress;
var eleicao;
const CONTRACT_ADDRESS = "0xcB9f4DCCB47Da76B78c237B28B26d8E1925A9447";


const ethEnabled = () => {
	if (window.ethereum) {
		window.web3 = new Web3(window.ethereum);
		window.ethereum.enable();
		return true;
	}
	return false;
}

const getMyAccounts = accounts => {
	try {
		if (accounts.length == 0) {
			alert("Você não tem contas habilitadas no Metamask!");
		} else {
			myAddress = accounts[0];
			accounts.forEach(async myAddress => {
				console.log(myAddress + " : " + await window.web3.eth.getBalance(myAddress));
			});
		}
	} catch (error) {
		console.log("Erro ao obter contas...");
	}
};

window.addEventListener('load', async function () {

	if (!ethEnabled()) {
		alert("Por favor, instale um navegador compatível com Ethereum ou uma extensão como o MetaMask para utilizar esse dApp!");
	}
	else {
		getMyAccounts(await web3.eth.getAccounts());

		eleicao = new web3.eth.Contract(VotingContractInterface, CONTRACT_ADDRESS);
		console.log(eleicao.options.address);
		isChairparson = await chairparson(eleicao);

		var statusVoting = await getStatusVoding(eleicao);

		if (isChairparson && statusVoting == 0) {
			$(".chairperson").removeClass("hidden").addClass("show");
		}

		await getProposals(eleicao, populaProposals);
		await getVoters(eleicao, setItensTableVoters);
	}
});

async function chairparson(contractRef) {
	return await contractRef.methods.chairperson().call().then((person) => {
		return myAddress === person;
	});
}

async function getProposals(contractRef, callback) {
	contractRef.methods.getProposalsCount().call(async function (error, count) {
		console.log(error);
		proposals = [];
		for (i = 0; i < count; i++) {
			await contractRef.methods.getProposal(i).call().then((data) => {
				var proposal = {
					name: data[0],
					voteCount: data[1]
				};
				proposals.push(proposal);
			});
		}
		if (callback) {
			await callback(proposals);
		}

	});
}

async function getVoters(contractRef, callback) {
	await contractRef.methods.getVoters().call().then(async (voters) => {
		if (callback) {
			await callback(voters)
		}
	})
}

async function getStatusVoding(contractRef) {
	return await contractRef.methods.getVotingStatus().call().then((votingStatus) => {
		if (votingStatus == 1) {
			$("#btnEndVote").prop('disabled', true);
			$(".chairperson").removeClass("show").addClass("hidden");
			$("#btnVote").removeClass("show").addClass("hidden");
			$("#voteDelegate").removeClass("show").addClass("hidden");
		}
		else {
			$("#btnVote").removeClass("hidden").addClass("show");
			$("#voteDelegate").removeClass("hidden").addClass("show");
			$("#btnEndVote").removeProp('disabled');
		}

		return votingStatus;
	})
}

async function getOnlyStatusVoding(contractRef) {
	return await contractRef.methods.getVotingStatus().call().then((votingStatus) => {
		return votingStatus;
	})
}

async function setItensTableVoters(voters) {
	$("#table-body-address").empty();
	voters.forEach((voter, index) => {
		markup = "<tr>\
		            <td>" + voter.name + "</td>\
					<td>" + (voter.voted ? '<span class="glyphicon glyphicon-ok green" aria-hidden="true"></span>' :
				'<span class="glyphicon glyphicon-remove red" aria-hidden="true"></span>') + "\
					</td>\
				  </tr>";
		tableBody = $("#table-body-address");
		tableBody.append(markup);
	})
}

async function populaProposals(candidatos) {
	tableElem.innerHTML = '';
	cmp = function(a, b) {
		if (a > b) return +1;
		if (a < b) return -1;
		return 0;
	}
	candidatos.sort(function (a, b) {
		return cmp(b.voteCount,a.voteCount) || cmp(a.name,b.name);
		// if (a.voteCount < b.voteCount) {
		// 	return 1;
		// }
		// if (a.voteCount > b.voteCount) {
		// 	return -1;
		// }
		// // a must be equal to b
		// return 0;
	});
	var statusVoting = await getOnlyStatusVoding(eleicao);

	candidatos.forEach((candidato, index) => {
		// Creates a row element.
		const rowElem = document.createElement("tr");

		if (statusVoting == 1 && index == 0) {
			rowElem.className = "bg-grenn";
		}

		// Creates a cell element for the name.
		const nameCell = document.createElement("td");
		nameCell.innerText = candidato.name;
		rowElem.appendChild(nameCell);

		// Creates a cell element for the votes.
		const voteCell = document.createElement("td");
		voteCell.id = "vote-" + candidato.name;
		voteCell.innerText = candidato.voteCount;
		rowElem.appendChild(voteCell);

		// Adds the new row to the voting table.
		tableElem.appendChild(rowElem);

		// Creates an option for each candidate
		const candidateOption = document.createElement("option");
		candidateOption.value = index;
		candidateOption.innerText = candidato.name;
		candidateOptions.appendChild(candidateOption);
	});
}


$("#btnVote").on('click', function () {
	candidato = $("#candidate-options").children("option:selected").val();
	eleicao.methods.vote(candidato).send({ from: myAddress })
		.on('confirmation', function (confirmationNumber, receipt) {
			getVoters(eleicao, setItensTableVoters)
		});
});

$("#btnProposal").on("click", function () {
	var proposalName = $("#proposalName").val();
	eleicao.methods.addProposal(proposalName).send({ from: myAddress })
		.on('transactionHash', function (hash) {
			console.log(hash);
		})
		.on('receipt', function (receipt) {
			console.log(receipt);
			getProposals(eleicao, populaProposals);
		})
		.on('confirmation', function (confirmationNumber, receipt) {
			console.log(confirmationNumber);
		})
		.on('error', function (error, receipt) {
			console.log(error);
		});
});

$("#btnEndVote").on("click", function () {
	eleicao.methods.finishVoting().send({ from: myAddress })
		.on('transactionHash', function (hash) {
			console.log(hash);
		})
		.on('receipt', function (receipt) {
			console.log(receipt);
		})
		.on('confirmation', function (confirmationNumber, receipt) {
			location.reload();
		})
		.on('error', function (error, receipt) {
			console.log(error);
		});
});

$("#btnVoters").on("click", function () {
	var address = $("#address").val();
	var name = new $("#name").val();
	eleicao.methods.giveRightToVote(address, name).send({ from: myAddress })
		.on('transactionHash', function (hash) {
			console.log(hash);
		})
		.on('receipt', function (receipt) {
			console.log(receipt);
			getVoters(eleicao, setItensTableVoters);
		})
		.on('confirmation', function (confirmationNumber, receipt) {
			console.log(confirmationNumber);
		})
		.on('error', function (error, receipt) {
			console.log(error);
		});
});

$("#btnDelegate").on("click", function () {
	var address = $("#addressDelegate").val();
	eleicao.methods.delegate(address).send({ from: myAddress })
		.on('transactionHash', function (hash) {
			console.log(hash);
		})
		.on('receipt', function (receipt) {
			console.log(receipt);
			getVoters(eleicao, setItensTableVoters);
		})
		.on('confirmation', function (confirmationNumber, receipt) {
			console.log(confirmationNumber);
		})
		.on('error', function (error, receipt) {
			console.log(error);
		});
});
