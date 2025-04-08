import { describe, it, expect, beforeEach, vi } from 'vitest';

// Mock the Clarity VM environment
const mockClarity = {
  blockHeight: 100,
  assets: new Map(),
  lastAssetId: 0,
  tx: {
    sender: 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM' // Mock principal
  }
};

// Mock the contract functions
const assetRegistration = {
  registerAsset: (name, description, serialNumber, acquisitionCost, currentValue) => {
    const newAssetId = mockClarity.lastAssetId + 1;
    mockClarity.lastAssetId = newAssetId;
    
    mockClarity.assets.set(newAssetId, {
      name,
      description,
      serialNumber,
      acquisitionDate: mockClarity.blockHeight,
      acquisitionCost,
      owner: mockClarity.tx.sender,
      status: 'available',
      currentValue
    });
    
    return { value: newAssetId };
  },
  
  updateAssetStatus: (assetId, newStatus) => {
    if (!mockClarity.assets.has(assetId)) {
      return { error: 404 };
    }
    
    const asset = mockClarity.assets.get(assetId);
    if (asset.owner !== mockClarity.tx.sender) {
      return { error: 403 };
    }
    
    asset.status = newStatus;
    mockClarity.assets.set(assetId, asset);
    return { value: true };
  },
  
  updateAssetValue: (assetId, newValue) => {
    if (!mockClarity.assets.has(assetId)) {
      return { error: 404 };
    }
    
    const asset = mockClarity.assets.get(assetId);
    if (asset.owner !== mockClarity.tx.sender) {
      return { error: 403 };
    }
    
    asset.currentValue = newValue;
    mockClarity.assets.set(assetId, asset);
    return { value: true };
  },
  
  getAsset: (assetId) => {
    return mockClarity.assets.get(assetId) || null;
  },
  
  getAssetCount: () => {
    return mockClarity.lastAssetId;
  }
};

describe('Asset Registration Contract', () => {
  beforeEach(() => {
    // Reset the mock state before each test
    mockClarity.assets = new Map();
    mockClarity.lastAssetId = 0;
  });
  
  it('should register a new asset', () => {
    const result = assetRegistration.registerAsset(
        'Forklift XL2000',
        'Heavy duty warehouse forklift',
        'FL-2000-123456',
        50000,
        45000
    );
    
    expect(result.value).toBe(1);
    expect(mockClarity.lastAssetId).toBe(1);
    
    const asset = assetRegistration.getAsset(1);
    expect(asset).not.toBeNull();
    expect(asset.name).toBe('Forklift XL2000');
    expect(asset.status).toBe('available');
    expect(asset.owner).toBe(mockClarity.tx.sender);
  });
  
  it('should update asset status', () => {
    // First register an asset
    assetRegistration.registerAsset(
        'Excavator M500',
        'Medium-sized excavator',
        'EX-500-789012',
        120000,
        100000
    );
    
    // Update its status
    const result = assetRegistration.updateAssetStatus(1, 'leased');
    expect(result.value).toBe(true);
    
    // Verify the status was updated
    const asset = assetRegistration.getAsset(1);
    expect(asset.status).toBe('leased');
  });
  
  it('should not allow unauthorized status updates', () => {
    // Register an asset
    assetRegistration.registerAsset(
        'Generator G100',
        'Portable generator',
        'GEN-100-345678',
        8000,
        7500
    );
    
    // Change the sender to simulate a different user
    const originalSender = mockClarity.tx.sender;
    mockClarity.tx.sender = 'ST2CY5V39NHDPWSXMW9QDT3HC3GD6Q6XX4CFRK9AG';
    
    // Try to update status
    const result = assetRegistration.updateAssetStatus(1, 'maintenance');
    expect(result.error).toBe(403);
    
    // Verify the status was not updated
    const asset = assetRegistration.getAsset(1);
    expect(asset.status).toBe('available');
    
    // Restore original sender
    mockClarity.tx.sender = originalSender;
  });
  
  it('should update asset value', () => {
    // Register an asset
    assetRegistration.registerAsset(
        'Crane T300',
        'Tower crane for construction',
        'CR-300-901234',
        200000,
        180000
    );
    
    // Update its value
    const result = assetRegistration.updateAssetValue(1, 170000);
    expect(result.value).toBe(true);
    
    // Verify the value was updated
    const asset = assetRegistration.getAsset(1);
    expect(asset.currentValue).toBe(170000);
  });
  
  it('should return the correct asset count', () => {
    expect(assetRegistration.getAssetCount()).toBe(0);
    
    // Register multiple assets
    assetRegistration.registerAsset('Asset 1', 'Description 1', 'SN1', 1000, 900);
    assetRegistration.registerAsset('Asset 2', 'Description 2', 'SN2', 2000, 1800);
    assetRegistration.registerAsset('Asset 3', 'Description 3', 'SN3', 3000, 2700);
    
    expect(assetRegistration.getAssetCount()).toBe(3);
  });
});
