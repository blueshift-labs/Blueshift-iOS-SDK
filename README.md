SDK for ecommerce application to enable push services / deeplinking with appropriate actions and internal analytics with blueshift server

To initialize the SDK, we need to set the following parameters as configuration. These parameters are mandatory to get SDK work properly.

API key: This is the unique api-key given to the client (Host App) by Blueshift.
Launch Options: This is the launchOptions dictionary that you receive when your app launches. This value needs to be set to SDK config.
Deep-link Pages: Setting proper pages (Activity) using setter methods are required to get the deep-link work properly. The SDK supports deep-linking to Product, Cart and Offer pages.
