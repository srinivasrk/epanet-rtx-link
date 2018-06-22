let shared = {
  postOpts:{
		method: 'post',
		headers: {'Content-Type': 'application/json'},
		credentials: 'include'
	},
  fetchOpts: {
    credentials: 'include'
  },
  alertHandler: (err) => {
    alert(err);
  },
  handleErrors: (response) => {
    if (response.ok) {
      return response;
    }
		else {
    	throw Error(`${response.statusText} ${response.url}`);
		}
	}
}


module.exports = {shared}
