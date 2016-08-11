# Promise

A Promise library for Swift, based partially on Javascript's A+ spec.

Promises are a way to chain asynchronous tasks. Normally, asynchronous tasks take a callback (or sometimes two, one for success and one for failure), in the form of a block, that is called when the asynchronous operation is completed. To perform more than one asynchronous operation, you have to nest the second one inside the completion block of the first one:

	APIClient.fetchCurrentUser(success: { currentUser in
		APIClient.fetchFollowers(user: currentUser, success: { followers in
			// you now have an array of followers
		}, failure: { error in
			// handle the error
		})
	}, failure: { error in
		// handle the error
	})
	
Promises are a way of formalizing these completion blocks to make chaining asynchronous processes much easier. If the system knows what success and what failure look like, composing those asynchronous operations becomes much easier. For example, it becomes trivial to write reusable code that can:

* perform a chain of dependent asynchronous operations with one completion block at the end
* perform many independent asynchronous operations simultaneously with one completion block
* race many asynchronous operations and return the value of the first to complete
* retry asynchronous operations
* add a timeout to asynchronous operations

The code sample above, when converted into promises, looks like this:

	APIClient.fetchCurrentUser().then({ currentUser in
		return APIClient.fetchFollowers(user: currentUser)
	}).then({ followers in
		// you now have an array of followers
	)}.onFailure({ error in
		// hooray, a single failure block!
	})

This library isn't ready for production yet.  It doesn't have public declarations or a podspec yet, because I haven't used it in live app yet.