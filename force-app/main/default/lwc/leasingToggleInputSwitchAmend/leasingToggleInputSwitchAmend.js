import { LightningElement, api } from 'lwc';
 
export default class LeasingToggleInputSwitchAmend extends LightningElement {
  @api label;
  @api name;
  @api amountPlaceholder;
  @api percentPlaceholder;
 
  @api type = 'Amount';
  @api value = 0;
 
  @api amountValue = 0;
  @api percentValue = 0;
 
  get discountOptions() {
    return [
      { label: 'Amount', value: 'Amount' },
      { label: 'Percentage', value: 'Percentage' }
    ];
  }
 
  get isPercent() {
    return this.type === 'Percentage';
  }
 
  get effectiveValue() {
    return this.isPercent ? (this.percentValue ?? this.value) : (this.amountValue ?? this.value);
  }
 
  handleTypeChange(event) {
    this.type = event.detail.value;
    this.sendValue(0); // reset
  }
 
  handleInputChange(event) {
    this.sendValue(event.target.value);
  }
 
  sendValue(val) {
    const myCustomEvent = new CustomEvent('valuechange', {
      detail: {
        name: this.name,
        type: this.type,
        value: Number(val) || 0
      }
    });
    this.dispatchEvent(myCustomEvent);
  }
}