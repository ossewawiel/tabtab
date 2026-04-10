// ===============================================================
// User handler file. TabTab NEVER overwrites files in handlers/.
// Edit freely — your code will survive every re-export.
// ===============================================================

package com.example.customermanager.handlers

/**
 * Event handlers referenced by customer-manager.tt.yaml.
 *
 * The generator emits calls to these functions but the implementations
 * belong to you. Add imports, parameters, and logic as needed.
 */

fun updateSearchQuery(newValue: String) {
    // The generated ViewModel will wire the TextField's onChange to this
    // function, which should push the new value into the searchQuery signal.
    // The signal update then triggers filteredCustomers recomputation automatically.
}

fun selectCustomer(customerId: String) {
    // Set selectedCustomerId and navigate. The generated NavHost handles
    // the actual screen transition based on the navigation.routes.on mapping.
}

fun goBack() {
    // Pops the back stack.
}
