class ApiConstants {
  // static const String baseUrl = 'https://krishilink.shamir.com.np';
  static const String baseUrl =
      'https://w1vqqn7ucvzpndp9xsvdkd15gzcedswvilahs3agd6b3dljo7tg24pbklk4u.shamir.com.np';
  //   static const String baseUrl = 'http://192.168.23.5';

  // -------------------- AUTH --------------------
  static const String registerEndpoint =
      '$baseUrl/api/KrishilinkAuth/registerUser';
  static const String sendConfirmationEmailEndpoint =
      '$baseUrl/api/KrishilinkAuth/sendConfirmationEmail';
  static const String confirmEmailEndpoint =
      '$baseUrl/api/KrishilinkAuth/ConfirmEmail';

  static const String passwordLoginEndpoint =
      '$baseUrl/api/KrishilinkAuth/passwordLogin';

  static const String sendOtpEndpoint = '$baseUrl/api/KrishilinkAuth/sendOTP';
  static const String verifyOtpEndpoint =
      '$baseUrl/api/KrishilinkAuth/verifyOTP';

  static const String refreshTokenEndpoint =
      '$baseUrl/api/KrishilinkAuth/refreshToken';

  static const String logoutEndpoint = '$baseUrl/api/KrishilinkAuth/logout';

  // -------------------- PRODUCT --------------------
  static const String getAllProductsEndpoint =
      '$baseUrl/api/Product/getProducts';
  static const String getProductByIdEndpoint =
      '$baseUrl/api/Product/getProduct'; // + /{productId}
  static const String getRelatedProductsEndpoint =
      '$baseUrl/api/Product/getRelatedProducts'; // + /{productId}
  static const String getProductImageEndpoint =
      '$baseUrl/api/Product/getProductImage'; // + /{productImageCode}

  static const String addProductEndpoint = '$baseUrl/api/Product/addProduct';
  static const String getMyProductsEndpoint =
      '$baseUrl/api/Product/getMyProducts';
  static const String getMyProductByIdEndpoint =
      '$baseUrl/api/Product/getMyProduct'; // + /{productId
  static const String updateProductEndpoint =
      '$baseUrl/api/Product/updateProduct'; // + /{productId}
  static const String deleteProductEndpoint =
      '$baseUrl/api/Product/deleteProduct'; // + /{productId}

  // -------------------- ORDER --------------------
  static const String placeOrderEndpoint = '$baseUrl/api/Order/addOrder';
  static const String addOrdersEndpoint = '$baseUrl/api/Order/addOrders';
  static const String getMyOrdersEndpoint = '$baseUrl/api/Order/getMyOrders';

  static const String cancelOrderEndpoint =
      '$baseUrl/api/Order/cancelOrder'; // + /{orderId}
  static const String confirmOrderEndpoint =
      '$baseUrl/api/Order/confirmOrder'; // + /{orderId}
  static const String shipOrderEndpoint =
      '$baseUrl/api/Order/shipOrder'; // + /{orderId}
  static const String deliverOrderEndpoint =
      '$baseUrl/api/Order/deliverOrder'; // + /{orderId}

  // -------------------- PAYMENT --------------------
  static const String initiatePaymentEndpoint =
      '$baseUrl/api/Payment/initiatePayment';
  static const String paymentSuccessEndpoint = '$baseUrl/api/Payment/success';
  static const String paymentFailureEndpoint = '$baseUrl/api/Payment/failure';

  // -------------------- REVIEW --------------------
  static const String addReviewEndpoint = '$baseUrl/api/Review/AddReview';
  static const String addOffensiveWordEndpoint =
      '$baseUrl/api/Review/AddOffensiveWord';
      
  static const String getProductReviewsEndpoint =
      '$baseUrl/api/Review/getProductReviews'; // + /{productId}
  static const String getNewReviewsEndpoint =
      '$baseUrl/api/Review/getNewReviews';
  static const String approveReviewEndpoint =
      '$baseUrl/api/Review/approveReview'; // + /{reviewId}

  // -------------------- USER --------------------
  static const String getUserDetailsEndpoint = '$baseUrl/api/User/GetDetails';
  static const String updateProfileEndpoint = '$baseUrl/api/User/UpdateProfile';
  static const String getUserImageEndpoint = '$baseUrl/api/User/getUserImage';
  static const String updateStatusEndpoint = '$baseUrl/api/User/updateStatus';
  static const String deleteUserEndpoint =
      '$baseUrl/api/User/Delete'; // + /{uid}

  // chat
  static const String getChatHistoryEndpoint =
      '$baseUrl/api/Chat/getChatHistory'; // + /{user2Id}
  static const String sendMessageEndpoint =
      '$baseUrl/api/Chat/sendMessage'; // + /{user2Id}

  // -------------------- MISC --------------------
  static const String getUserDetailsByPhoneNumber =
      '$baseUrl/api/User/GetUserDetailsByPhoneNumber/';
  static const String getUserDetailsByEmail =
      '$baseUrl/api/User/GetUserDetailsByEmail/';
  // -------------------- MISC --------------------

  // weatherEndpoints
  static const String getWeatherEndpoint =
      '$baseUrl/api/Weather/getWeatherDetails'; // + /{latitude}/{longitude}

  // --------------------------------------Cart -----------------------------------------

  static String getCartEndpoint = '$baseUrl/api/Product/getCartItems';

  static const String addToCartEndpoint = '$baseUrl/api/Cart/addToCart';

  static String removeFromCartEndpoint = '$baseUrl/api/Product/removeFromCart';

  static String healthEndpoint = ' $baseUrl/api/Health';

  static String chatWithAiEndpoint = '$baseUrl/api/AI/chatWithAI';

  static var updateProductStatusEndpoint =
      '$baseUrl/api/Product/updateProductStatus'; // + /{productId}

  static String getCropsEndpoint = '$baseUrl/api/Product/getCrops';

  static String getTutorialsEndpoint = '$baseUrl/api/Product/getTutorials';

  static String addCropEndpoint = '$baseUrl/api/Product/addCrop';

  static var updateCropEndpoint =
      '$baseUrl/api/Product/updateCrop'; // + /{cropId}

  static var deleteCropEndpoint =
      '$baseUrl/api/Product/deleteCrop'; // + /{cropId}

  static String getOrdersEndpoint = '$baseUrl/api/Product/getOrders';

  static String getNotificationsEndpoint =
      '$baseUrl/api/Notification/GetNotifications';

  static var markNotificationAsReadEndpoint =
      '$baseUrl/api/Notification/markNotificationAsRead';

  static var deleteOrderEndpoint; // + /{notificationId}

  // You can add more endpoints here if the Swagger spec updates
}


/*// class ApiConstants {
//   static const String baseUrl = 'https://krishilink.shamir.com.np';

//   // -------------------- AUTH --------------------
//   static const String registerEndpoint =
//       '$baseUrl/api/KrishilinkAuth/registerUser';
//   static const String sendConfirmationEmailEndpoint =
//       '$baseUrl/api/KrishilinkAuth/sendConfirmationEmail';
//   static const String confirmEmailEndpoint =
//       '$baseUrl/api/KrishilinkAuth/ConfirmEmail';

//   static const String passwordLoginEndpoint =
//       '$baseUrl/api/KrishilinkAuth/passwordLogin';

//   static const String sendOtpEndpoint = '$baseUrl/api/KrishilinkAuth/sendOTP';
//   static const String verifyOtpEndpoint =
//       '$baseUrl/api/KrishilinkAuth/verifyOTP';

//   static const String refreshTokenEndpoint =
//       '$baseUrl/api/KrishilinkAuth/refreshToken';
//   static const String logoutEndpoint = '$baseUrl/api/KrishilinkAuth/logout';

//   // -------------------- PRODUCT --------------------
//   static const String getAllProductsEndpoint =
//       '$baseUrl/api/Product/getProducts';
//   static const String getProductByIdEndpoint =
//       '$baseUrl/api/Product/getProduct'; // + /{productId}
//   static const String getRelatedProductsEndpoint =
//       '$baseUrl/api/Product/getRelatedProducts'; // + /{productId}
//   static const String getProductImageEndpoint =
//       '$baseUrl/api/Product/getProductImage'; // + /{productImageCode}

//   static const String addProductEndpoint = '$baseUrl/api/Product/addProduct';
//   static const String getMyProductsEndpoint =
//       '$baseUrl/api/Product/getMyProducts';
//   static const String getMyProductByIdEndpoint =
//       '$baseUrl/api/Product/getMyProduct'; // + /{productId}
//   static const String updateProductEndpoint =
//       '$baseUrl/api/Product/updateProduct'; // + /{productId}
//   static const String deleteProductEndpoint =
//       '$baseUrl/api/Product/deleteProduct'; // + /{productId}

//   // -------------------- ORDER --------------------
//   static const String placeOrderEndpoint = '$baseUrl/api/Order/addOrder';
//   static const String addOrdersEndpoint = '$baseUrl/api/Order/addOrders';
//   static const String getMyOrdersEndpoint = '$baseUrl/api/Order/getMyOrders';

//   static const String cancelOrderEndpoint =
//       '$baseUrl/api/Order/cancelOrder'; // + /{orderId}
//   static const String confirmOrderEndpoint =
//       '$baseUrl/api/Order/confirmOrder'; // + /{orderId}
//   static const String shipOrderEndpoint =
//       '$baseUrl/api/Order/shipOrder'; // + /{orderId}
//   static const String deliverOrderEndpoint =
//       '$baseUrl/api/Order/deliverOrder'; // + /{orderId}

//   // -------------------- PAYMENT --------------------
//   static const String initiatePaymentEndpoint =
//       '$baseUrl/api/Payment/initiatePayment';
//   static const String paymentSuccessEndpoint = '$baseUrl/api/Payment/success';
//   static const String paymentFailureEndpoint = '$baseUrl/api/Payment/failure';

//   // -------------------- REVIEW --------------------
//   static const String addReviewEndpoint = '$baseUrl/api/Review/AddReview';
//   static const String addOffensiveWordEndpoint =
//       '$baseUrl/api/Review/AddOffensiveWord';
//   static const String getProductReviewsEndpoint =
//       '$baseUrl/api/Review/getProductReviews'; // + /{productId}
//   static const String getNewReviewsEndpoint =
//       '$baseUrl/api/Review/getNewReviews';
//   static const String approveReviewEndpoint =
//       '$baseUrl/api/Review/approveReview'; // + /{reviewId}

//   // -------------------- USER --------------------
//   static const String getUserDetailsEndpoint = '$baseUrl/api/User/GetDetails';
//   static const String updateProfileEndpoint = '$baseUrl/api/User/UpdateProfile';
//   static const String getUserImageEndpoint = '$baseUrl/api/User/getUserImage';
//   static const String updateStatusEndpoint = '$baseUrl/api/User/updateStatus';
//   static const String deleteUserEndpoint =
//       '$baseUrl/api/User/Delete'; // + /{uid}

//   // -------------------- MISC --------------------
//   static const String getUserDetailsByPhoneNumber =
//       '$baseUrl/api/User/GetUserDetailsByPhoneNumber/';
//   // -------------------- MISC --------------------

//   // --------------------------------------Cart -----------------------------------------

//   static String getCartEndpoint = '$baseUrl/api/Product/getCartItems';

//   static String addToCartEndpoint = '$baseUrl/api/Product/addToCart';

//   static String removeFromCartEndpoint = '$baseUrl/api/Product/removeFromCart';

//   // You can add more endpoints here if the Swagger spec updates
// }
class ApiConstants {
  static const String baseUrl = 'https://krishilink.shamir.com.np';

  // -------------------- AUTH --------------------
  static const String registerEndpoint =
      '$baseUrl/api/KrishilinkAuth/registerUser';
  static const String sendConfirmationEmailEndpoint =
      '$baseUrl/api/KrishilinkAuth/sendConfirmationEmail';
  static const String confirmEmailEndpoint =
      '$baseUrl/api/KrishilinkAuth/ConfirmEmail';
  static const String passwordLoginEndpoint =
      '$baseUrl/api/KrishilinkAuth/passwordLogin';
  static const String sendOtpEndpoint = '$baseUrl/api/KrishilinkAuth/sendOTP';
  static const String verifyOtpEndpoint =
      '$baseUrl/api/KrishilinkAuth/verifyOTP';
  static const String refreshTokenEndpoint =
      '$baseUrl/api/KrishilinkAuth/refreshToken';
  static const String logoutEndpoint = '$baseUrl/api/KrishilinkAuth/logout';

  // -------------------- PRODUCT --------------------
  static const String addProductEndpoint = '$baseUrl/api/Product/addProduct';
  static const String getAllProductsEndpoint =
      '$baseUrl/api/Product/getProducts';
  static const String getProductByIdEndpoint =
      '$baseUrl/api/Product/getProduct'; // + /{productId}
  static const String getRelatedProductsEndpoint =
      '$baseUrl/api/Product/getRelatedProducts'; // + /{productId}
  static const String getProductImageEndpoint =
      '$baseUrl/api/Product/getProductImage'; // + /{productImageCode}
  static const String getMyProductsEndpoint =
      '$baseUrl/api/Product/getMyProducts';
  static const String getMyProductByIdEndpoint =
      '$baseUrl/api/Product/getMyProduct'; // + /{productId}
  static const String updateProductEndpoint =
      '$baseUrl/api/Product/updateProduct'; // + /{productId}
  static const String deleteProductEndpoint =
      '$baseUrl/api/Product/deleteProduct'; // + /{productId}

  // -------------------- ORDER --------------------
  static const String placeOrderEndpoint = '$baseUrl/api/Order/addOrder';
  static const String addOrdersEndpoint = '$baseUrl/api/Order/addOrders';
  static const String cancelOrderEndpoint =
      '$baseUrl/api/Order/cancelOrder'; // + /{orderId}
  static const String confirmOrderEndpoint =
      '$baseUrl/api/Order/confirmOrder'; // + /{orderId}
  static const String shipOrderEndpoint =
      '$baseUrl/api/Order/shipOrder'; // + /{orderId}
  static const String deliverOrderEndpoint =
      '$baseUrl/api/Order/deliverOrder'; // + /{orderId}
  static const String getMyOrdersEndpoint = '$baseUrl/api/Order/getMyOrders';

  // -------------------- REVIEW --------------------
  static const String addReviewEndpoint = '$baseUrl/api/Review/AddReview';
  static const String getProductReviewsEndpoint =
      '$baseUrl/api/Review/getProductReviews'; // + /{productId}
  static const String deleteReviewEndpoint =
      '$baseUrl/api/Review/DeleteReview'; // + /{reviewId}

  // -------------------- USER --------------------
  static const String getAllUsersEndpoint = '$baseUrl/api/User/GetAllUsers';
  static const String getAllFarmersEndpoint = '$baseUrl/api/User/GetAllFarmers';
  static const String getAllBuyersEndpoint = '$baseUrl/api/User/GetAllBuyers';
  static const String getAllActiveUsersEndpoint =
      '$baseUrl/api/User/GetAllActiveUsers';
  static const String getUserDetailsByIdEndpoint =
      '$baseUrl/api/User/GetUserDetailsById'; // + ?userId=...
  static const String getUserDetailsByPhoneNumberEndpoint =
      '$baseUrl/api/User/GetUserDetailsByPhoneNumber'; // + /{phoneNumber}
  static const String getUserDetailsByEmailEndpoint =
      '$baseUrl/api/User/GetUserDetailsByEmail'; // + ?email=...
  static const String getMyDetailsEndpoint = '$baseUrl/api/User/GetMyDetails';
  static const String getUserImageEndpoint = '$baseUrl/api/User/getUserImage';
  static const String updateProfileEndpoint = '$baseUrl/api/User/UpdateProfile';
  static const String updateStatusEndpoint = '$baseUrl/api/User/updateStatus';
  static const String deleteUserEndpoint =
      '$baseUrl/api/User/Delete'; // + /{userId}

  // -------------------- CART --------------------
  static const String getCartEndpoint = '$baseUrl/api/Product/getCartItems';
  static const String addToCartEndpoint = '$baseUrl/api/Cart/addToCart';
  static const String removeFromCartEndpoint = '$baseUrl/api/Product/removeFromCart';

  // -------------------- AI --------------------
  static const String chatWithAiEndpoint = '$baseUrl/api/AI/GetChatWithAI';

  // -------------------- HEALTH --------------------
  static const String healthEndpoint = '$baseUrl/api/Health';

  // -------------------- PAYMENT (Assumed) --------------------
  static const String initiatePaymentEndpoint =
      '$baseUrl/api/Payment/initiatePayment';
  static const String paymentSuccessEndpoint = '$baseUrl/api/Payment/success';
  static const String paymentFailureEndpoint = '$baseUrl/api/Payment/failure';
  }*/