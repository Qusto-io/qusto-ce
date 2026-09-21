import { classifyChannel, isChannelRelevant } from '../src/track.js';

describe('Channel Classifier', () => {
  describe('isChannelRelevant', () => {
    it('should return true if source is present', () => {
      expect(isChannelRelevant('google.com', '', '')).toBe(true);
    });
    
    it('should return true if utm_medium is present', () => {
      expect(isChannelRelevant('', 'cpc', '')).toBe(true);
    });
    
    it('should return true if utm_source is present', () => {
      expect(isChannelRelevant('', '', 'newsletter')).toBe(true);
    });
    
    it('should return false if no channel-relevant params are present', () => {
      expect(isChannelRelevant('', '', '')).toBe(false);
    });
  });
  
  describe('classifyChannel', () => {
    it('should classify as paid_search for utm_medium=cpc', () => {
      expect(classifyChannel('google', 'cpc', '', '', '')).toBe('paid_search');
    });
    
    it('should classify as paid_search for utm_medium=ppc', () => {
      expect(classifyChannel('google', 'ppc', '', '', '')).toBe('paid_search');
    });
    
    it('should classify as paid_search for utm_source=adwords', () => {
      expect(classifyChannel('google', '', '', 'adwords', '')).toBe('paid_search');
    });
    
    it('should classify as paid_search for google with gclid', () => {
      expect(classifyChannel('google', '', '', '', 'gclid')).toBe('paid_search');
    });
    
    it('should classify as paid_search for bing with msclkid', () => {
      expect(classifyChannel('bing', '', '', '', 'msclkid')).toBe('paid_search');
    });
    
    it('should classify as email for utm_medium=email', () => {
      expect(classifyChannel('', 'email', '', '', '')).toBe('email');
    });
    
    it('should classify as email for utm_medium=newsletter', () => {
      expect(classifyChannel('', 'newsletter', '', '', '')).toBe('email');
    });
    
    it('should classify as email for utm_source containing email', () => {
      expect(classifyChannel('', '', '', 'email_marketing', '')).toBe('email');
    });
    
    it('should classify as social for facebook referrer', () => {
      expect(classifyChannel('facebook', '', '', '', '')).toBe('social');
    });
    
    it('should classify as social for utm_medium=social', () => {
      expect(classifyChannel('', 'social', '', '', '')).toBe('social');
    });
    
    it('should classify as organic_search for google referrer', () => {
      expect(classifyChannel('google', '', '', '', '')).toBe('organic_search');
    });
    
    it('should classify as referral for external referrer', () => {
      expect(classifyChannel('example.com', '', '', '', '')).toBe('referral');
    });
    
    it('should classify as direct for no referrer and no UTM params', () => {
      expect(classifyChannel('', '', '', '', '')).toBe('direct');
    });
  });
});
