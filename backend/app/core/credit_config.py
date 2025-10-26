"""
Credit Configuration - Centralized credit cost mapping
This file defines how many credits each service consumes.
Modify here to change credit costs across the entire app.

CREDIT SYSTEM OVERVIEW:
- Free users: Must purchase credits or earn them
- Premium users: Have unlimited access + receive monthly/yearly credit allowance
  - Premium users CAN use services without credits being deducted
  - They still receive and keep their credit allowance
  - Credits accumulate over time (they never expire)
"""

from enum import Enum
from typing import Dict

class ServiceType(Enum):
    """Different service types available in the app"""
    PHOTO_RESTORE = "photo_restore"
    MEMORY_MERGE = "memory_merge"
    CINEMATIC_FILTER = "cinematic_filter"
    # Add more services as needed

# Credit cost mapping - Modify here to change costs
# These costs apply to FREE users. Premium users have unlimited access.
SERVICE_CREDIT_COSTS: Dict[ServiceType, int] = {
    ServiceType.PHOTO_RESTORE: 1,      # 1 credit for photo restoration
    ServiceType.MEMORY_MERGE: 2,       # 2 credits for merging memories (more complex)
    ServiceType.CINEMATIC_FILTER: 3,  # 3 credits for cinematic filters (premium feature)
}

def get_credit_cost(service_type: ServiceType) -> int:
    """
    Get the credit cost for a specific service.
    
    Args:
        service_type: The type of service being used
        
    Returns:
        Number of credits required for the service
    """
    return SERVICE_CREDIT_COSTS.get(service_type, 1)  # Default to 1 credit

def get_all_costs() -> Dict[str, int]:
    """
    Get all service costs in a simple dictionary format.
    
    Returns:
        Dictionary mapping service names to credit costs
    """
    return {
        service.value: cost 
        for service, cost in SERVICE_CREDIT_COSTS.items()
    }

# Monthly credit allocations
FREE_MONTHLY_CREDITS = 3           # Free users get 3 credits per month
INITIAL_SIGNUP_CREDITS = 3         # Initial credits on signup (matches monthly allocation)

# Premium subscription benefits
PREMIUM_UNLIMITED = True                   # Premium users have unlimited access to services
PREMIUM_SOFT_LIMIT = 100                  # Internal soft limit for premium users (uses/month for cost control)
PREMIUM_CREDITS_ON_UPGRADE = 50           # Bonus credits when upgrading to premium
PREMIUM_MONTHLY_RENEWAL_BONUS = 0         # No monthly bonus (unlimited access is the benefit)
PREMIUM_YEARLY_BONUS = 200                # Bonus credits for yearly subscribers

# How Premium Credits Work:
# - Premium users receive credits but DON'T have to use them for services (unlimited access)
# - Credits accumulate over time and NEVER expire
# - Premium users can still gift credits to others if needed
# - They have both: unlimited access + accumulating credits
