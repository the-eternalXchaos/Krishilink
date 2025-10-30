class ApiConstants {
  static const String baseUrl =
      'https://w1vqqn7ucvzpndp9xsvdkd15gzcedswvilahs3agd6b3dljo7tg24pbklk4u.shamir.com.np';

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
  static const String getProductLocationLatitudeLongitudeEndpoint =
      '$baseUrl/api/Product/getProductLocationLatitudeLongitude'; // + /{productId}
  static const String getNearProductsEndpoint =
      '$baseUrl/api/Product/getNearProducts'; // + /{latitude},{longitude}
  static const String getProductImageEndpoint =
      '$baseUrl/api/Product/getProductImage'; // + /{productImageCode}
  static const String getMyProductsEndpoint =
      '$baseUrl/api/Product/getMyProducts';
  static const String getMyProductByIdEndpoint =
      '$baseUrl/api/Product/getMyProduct'; // + /{productId}
  static const String updateProductEndpoint =
      '$baseUrl/api/Product/updateProduct'; // + /{productId}
  static const String updateProductStatusEndpoint =
      '$baseUrl/api/Product/updateProductStatus'; // + /{productId}
  static const String updateProductActiveStatusEndpoint =
      '$baseUrl/api/Product/updateProductActiveStatus'; // + /{productId}
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
  static const String getFarmerOrdersEndpoint =
      '$baseUrl/api/Order/getFarmerOrders';
  static const String getBuyerOrdersEndpoint =
      '$baseUrl/api/Order/getBuyerOrders';
  static const String deleteOrderEndpoint =
      '$baseUrl/api/Order/deleteOrder'; // + /{orderId}

  // Item-level and extra order endpoints per docs
  static const String cancelOrderItemEndpoint =
      '$baseUrl/api/Order/cancelOrderItem'; // + /{orderId}/{orderItemId}
  static const String confirmOrderItemEndpoint =
      '$baseUrl/api/Order/confirmOrderItem'; // + /{orderItemId}
  static const String shipOrderItemEndpoint =
      '$baseUrl/api/Order/shipOrderItem'; // + /{orderItemId}
  static const String deliverOrderItemEndpoint =
      '$baseUrl/api/Order/deliverOrderItem'; // + /{orderItemId}
  static const String markAsDeliveryEndpoint =
      '$baseUrl/api/Order/markAsDelivery'; // + /{orderItemId}
  static const String getCustomerOrdersEndpoint =
      '$baseUrl/api/Order/getCustomerOrders';

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
  static const String deleteReviewEndpoint =
      '$baseUrl/api/Review/DeleteReview'; // + /{reviewId}
  static const String editReviewEndpoint =
      '$baseUrl/api/Review/UpdateReview'; // + /{reviewId}  and message

  static const String getMyReviewsEndpoint = '$baseUrl/api/Review/getMyReviews';

  // -------------------- USER --------------------
  static const String getAllUsersEndpoint = '$baseUrl/api/User/GetAllUsers';
  static const String getAllFarmersEndpoint = '$baseUrl/api/User/GetAllFarmers';
  static const String getAllBuyersEndpoint = '$baseUrl/api/User/GetAllBuyers';
  static const String getAllActiveUsersEndpoint =
      '$baseUrl/api/User/GetAllActiveUsers';
  static const String getUserDetailsByIdEndpoint =
      '$baseUrl/api/User/GetUserDetailsById'; // + ?userId=...
  static const String getUserDetailsByPhoneNumberEndpoint =
      '$baseUrl/api/User/GetUserDetailsByPhoneNumber'; // + ?phoneNumber=...
  static const String getUserDetailsByEmailEndpoint =
      '$baseUrl/api/User/GetUserDetailsByEmail'; // + ?email=...
  static const String getMyDetailsEndpoint = '$baseUrl/api/User/GetMyDetails';
  static const String getUserImageEndpoint = '$baseUrl/api/User/getUserImage';
  static const String getUserImageByIdEndpoint =
      '$baseUrl/api/User/getUserImageById'; // + /{userId}
  static const String getUserNameByIdEndpoint =
      '$baseUrl/api/User/getUserNameById'; // + /{userId}
  static const String updateProfileEndpoint = '$baseUrl/api/User/UpdateProfile';
  static const String updateStatusEndpoint =
      '$baseUrl/api/User/updateStatus'; // + /{status}
  static const String deleteUserEndpoint =
      '$baseUrl/api/User/Delete'; // + /{userId}

  // -------------------- CART --------------------
  static const String getCartEndpoint = '$baseUrl/api/Cart/getMyCart';
  static const String addToCartEndpoint = '$baseUrl/api/Cart/addToCart';
  static const String removeFromCartEndpoint =
      '$baseUrl/api/Cart/removeFromCart';
  static const String clearCartEndpoint = '$baseUrl/api/Cart/clearCart';

  // -------------------- AI --------------------
  static const String chatWithAiEndpoint = '$baseUrl/api/AI/chatWithAI';
  static const String getAiChatsEndpoint = '$baseUrl/api/AI/getAIChats';
  static const String getAiChatMessagesEndpoint =
      '$baseUrl/api/AI/getAIChatMessages'; // + /{aiChatId}
  static const String deleteAiChatEndpoint =
      '$baseUrl/api/AI/deleteAIChat'; // + /{aiChatId}
  static const String detectDiseaseEndpoint = '$baseUrl/api/AI/detectDisease';
  static const String detectOffensiveContentEndpoint =
      '$baseUrl/api/AI/detectOffensiveContent';

  // -------------------- HEALTH --------------------
  static const String healthEndpoint = '$baseUrl/api/Health';

  // -------------------- PAYMENT --------------------
  static const String initiatePaymentEndpoint =
      '$baseUrl/api/Payment/initiatePayment';
  static const String paymentSuccessEndpoint = '$baseUrl/api/Payment/success';
  static const String paymentFailureEndpoint = '$baseUrl/api/Payment/failure';

  // Specific payment flows
  static const String initiateEsewaPaymentEndpoint =
      '$baseUrl/api/Payment/initiatePaymentForEsewa';
  static const String esewaSuccessEndpoint =
      '$baseUrl/api/Payment/esewaSuccess';
  static const String esewaFailureEndpoint = '$baseUrl/api/Payment/failure';
  // eSewa form action URL (test environment by default)
  static const String esewaFormUrl =
      'https://rc-epay.esewa.com.np/api/epay/main/v2/form';

  static const String initiateKhaltiPaymentEndpoint =
      '$baseUrl/api/Payment/initiatePaymentForKhalti';
  static const String khaltiResponseEndpoint =
      '$baseUrl/api/Payment/khaltiResponse';

  static const String cashOnDeliveryEndpoint =
      '$baseUrl/api/Payment/cashOnDelivery';

  // -------------------- CHAT --------------------
  static const String getChatHistoryEndpoint =
      '$baseUrl/api/Chat/getChatHistory'; // + /{user2Id}
  static const String sendMessageEndpoint =
      '$baseUrl/api/Chat/sendMessage'; // + /{user2Id}
  static const String getFarmerIdByProductIdEndpoint =
      '$baseUrl/api/Chat/getFarmerIdByProductId'; // + /{productId}
  static const String isFarmerLiveEndpoint =
      '$baseUrl/api/Chat/IsFarmerLive'; // + /{productId}
  static const String getMyCustomersForChatEndpoint =
      '$baseUrl/api/Chat/getMyCustomersForChat';

  // -------------------- WEATHER --------------------
  static const String getWeatherEndpoint =
      '$baseUrl/api/Weather/getWeatherDetails'; // + ?latitude=...&longitude=...

  // -------------------- NOTIFICATION --------------------
  static const String getNotificationsEndpoint =
      '$baseUrl/api/Notification/GetNotifications';
  static const String markNotificationAsReadEndpoint =
      '$baseUrl/api/Notification/MarkAsRead'; // + /{notificationId}
  static const String deleteNotificationEndpoint =
      '$baseUrl/api/Notification/DeleteNotification'; // + /{notificationId}
  static const String clearAllNotificationsEndpoint =
      '$baseUrl/api/Notification/ClearAllNotifications';
  static const String markAllNotificationsAsReadEndpoint =
      '$baseUrl/api/Notification/MarkAllAsRead';

  // -------------------- CROPS --------------------
  static const String getCropsEndpoint = '$baseUrl/api/Product/getCrops';
  static const String addCropEndpoint = '$baseUrl/api/Product/addCrop';
  static const String updateCropEndpoint =
      '$baseUrl/api/Product/updateCrop'; // + /{cropId}
  static const String deleteCropEndpoint =
      '$baseUrl/api/Product/deleteCrop'; // + /{cropId}

  // -------------------- TUTORIALS --------------------
  static const String getTutorialsEndpoint =
      '$baseUrl/api/Product/getTutorials';
}
