package com.example.crave.ui

import androidx.compose.foundation.layout.padding
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Favorite
import androidx.compose.material.icons.filled.Home
import androidx.compose.material.icons.filled.Person
import androidx.compose.material.icons.filled.Search
import androidx.compose.material.icons.filled.ShoppingCart
import androidx.compose.material3.Badge
import androidx.compose.material3.BadgedBox
import androidx.compose.material3.Icon
import androidx.compose.material3.NavigationBar
import androidx.compose.material3.NavigationBarItem
import androidx.compose.material3.Scaffold
import androidx.compose.material3.SnackbarHost
import androidx.compose.material3.SnackbarHostState
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.ui.Modifier
import androidx.navigation.NavDestination
import androidx.navigation.NavDestination.Companion.hierarchy
import androidx.navigation.NavType
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.currentBackStackEntryAsState
import androidx.navigation.compose.rememberNavController
import androidx.navigation.navArgument
import com.example.crave.data.repository.MockCartRepository
import com.example.crave.data.repository.MockFoodRepository
import com.example.crave.navigation.Screen
import com.example.crave.ui.screens.CartScreen
import com.example.crave.ui.screens.CheckoutScreen
import com.example.crave.ui.screens.FavouritesScreen
import com.example.crave.ui.screens.FoodDetailsScreen
import com.example.crave.ui.screens.HomeScreen
import com.example.crave.ui.screens.LoginScreen
import com.example.crave.ui.screens.OrderSuccessScreen
import com.example.crave.ui.screens.ProfileScreen
import com.example.crave.ui.screens.SearchScreen
import com.example.crave.ui.screens.SignUpScreen
import com.example.crave.ui.screens.SplashScreen
import com.example.crave.ui.screens.WelcomeScreen
import com.example.crave.viewmodel.AuthViewModel
import com.example.crave.viewmodel.CraveViewModel
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch

private data class BottomDestination(
    val route: String,
    val label: String,
    val icon: androidx.compose.ui.graphics.vector.ImageVector
)

@Composable
fun CraveApp() {
    val navController = rememberNavController()
    val craveViewModel = remember {
        CraveViewModel(MockFoodRepository(), MockCartRepository())
    }
    val authViewModel = remember { AuthViewModel() }
    val cartItems by craveViewModel.cartItems.collectAsState()
    val snackbarHostState = remember { SnackbarHostState() }
    val scope = rememberCoroutineScope()
    val backStackEntry by navController.currentBackStackEntryAsState()
    val currentDestination = backStackEntry?.destination

    val bottomDestinations = listOf(
        BottomDestination(Screen.Home, "Home", Icons.Default.Home),
        BottomDestination(Screen.Search, "Search", Icons.Default.Search),
        BottomDestination(Screen.Cart, "Cart", Icons.Default.ShoppingCart),
        BottomDestination(Screen.Favourites, "Favourites", Icons.Default.Favorite),
        BottomDestination(Screen.Profile, "Profile", Icons.Default.Person)
    )
    val showBottomBar = currentDestination?.route in bottomDestinations.map { it.route }
    val showMessage: (String) -> Unit = { message ->
        scope.launch { snackbarHostState.showSnackbar(message) }
    }

    Scaffold(
        snackbarHost = { SnackbarHost(snackbarHostState) },
        bottomBar = {
            if (showBottomBar) {
                NavigationBar {
                    bottomDestinations.forEach { destination ->
                        val selected = currentDestination.isInHierarchy(destination.route)
                        NavigationBarItem(
                            selected = selected,
                            onClick = {
                                navController.navigate(destination.route) {
                                    popUpTo(Screen.Home) { saveState = true }
                                    launchSingleTop = true
                                    restoreState = true
                                }
                            },
                            icon = {
                                if (destination.route == Screen.Cart && cartItems.isNotEmpty()) {
                                    BadgedBox(badge = { Badge { androidx.compose.material3.Text(cartItems.sumOf { it.quantity }.toString()) } }) {
                                        Icon(destination.icon, contentDescription = destination.label)
                                    }
                                } else {
                                    Icon(destination.icon, contentDescription = destination.label)
                                }
                            },
                            label = { androidx.compose.material3.Text(destination.label) }
                        )
                    }
                }
            }
        }
    ) { innerPadding ->
        NavHost(
            navController = navController,
            startDestination = Screen.Splash,
            modifier = Modifier.padding(innerPadding)
        ) {
            composable(Screen.Splash) {
                LaunchedEffect(Unit) {
                    delay(1_500)
                    navController.navigate(Screen.Welcome) {
                        popUpTo(Screen.Splash) { inclusive = true }
                    }
                }
                SplashScreen()
            }
            composable(Screen.Welcome) {
                WelcomeScreen(
                    onLogin = { navController.navigate(Screen.Login) },
                    onSignUp = { navController.navigate(Screen.SignUp) }
                )
            }
            composable(Screen.Login) {
                LoginScreen(
                    viewModel = authViewModel,
                    onBack = { navController.popBackStack() },
                    onSignUp = { navController.navigate(Screen.SignUp) },
                    onSuccess = {
                        navController.navigate(Screen.Home) {
                            popUpTo(Screen.Welcome) { inclusive = true }
                        }
                    },
                    showMessage = showMessage
                )
            }
            composable(Screen.SignUp) {
                SignUpScreen(
                    viewModel = authViewModel,
                    onBack = { navController.popBackStack() },
                    onLogin = { navController.navigate(Screen.Login) { popUpTo(Screen.SignUp) { inclusive = true } } },
                    onSuccess = {
                        navController.navigate(Screen.Home) {
                            popUpTo(Screen.Welcome) { inclusive = true }
                        }
                    }
                )
            }
            composable(Screen.Home) {
                HomeScreen(
                    viewModel = craveViewModel,
                    onFoodClick = { navController.navigate(Screen.foodDetails(it)) },
                    onSearchClick = { navController.navigate(Screen.Search) },
                    onCartClick = { navController.navigate(Screen.Cart) },
                    showMessage = showMessage
                )
            }
            composable(Screen.Search) {
                SearchScreen(
                    viewModel = craveViewModel,
                    onFoodClick = { navController.navigate(Screen.foodDetails(it)) },
                    showMessage = showMessage
                )
            }
            composable(Screen.Cart) {
                CartScreen(
                    viewModel = craveViewModel,
                    onContinueShopping = { navController.navigate(Screen.Home) },
                    onCheckout = { navController.navigate(Screen.Checkout) }
                )
            }
            composable(Screen.Favourites) {
                FavouritesScreen(
                    viewModel = craveViewModel,
                    onFoodClick = { navController.navigate(Screen.foodDetails(it)) },
                    onExplore = { navController.navigate(Screen.Home) },
                    showMessage = showMessage
                )
            }
            composable(Screen.Profile) {
                ProfileScreen(
                    viewModel = craveViewModel,
                    onLogout = {
                        navController.navigate(Screen.Welcome) {
                            popUpTo(Screen.Home) { inclusive = true }
                        }
                    },
                    onFavourites = { navController.navigate(Screen.Favourites) },
                    showMessage = showMessage
                )
            }
            composable(
                route = Screen.FoodDetails,
                arguments = listOf(navArgument("foodId") { type = NavType.StringType })
            ) { entry ->
                FoodDetailsScreen(
                    foodId = entry.arguments?.getString("foodId").orEmpty(),
                    viewModel = craveViewModel,
                    onBack = { navController.popBackStack() },
                    onCart = { navController.navigate(Screen.Cart) },
                    showMessage = showMessage
                )
            }
            composable(Screen.Checkout) {
                CheckoutScreen(
                    viewModel = craveViewModel,
                    onBack = { navController.popBackStack() },
                    onOrderPlaced = {
                        val order = craveViewModel.placeOrder(cartItems)
                        if (order != null) {
                            navController.navigate(Screen.OrderSuccess) {
                                popUpTo(Screen.Home)
                            }
                        } else {
                            showMessage("Your cart is empty.")
                        }
                    }
                )
            }
            composable(Screen.OrderSuccess) {
                OrderSuccessScreen(
                    order = craveViewModel.order.collectAsState().value,
                    onHome = {
                        navController.navigate(Screen.Home) {
                            popUpTo(Screen.Home) { inclusive = true }
                        }
                    },
                    onTrack = { showMessage("Your order is being prepared. We'll keep you updated!") }
                )
            }
        }
    }
}

private fun NavDestination?.isInHierarchy(route: String): Boolean =
    this?.hierarchy?.any { it.route == route } == true
