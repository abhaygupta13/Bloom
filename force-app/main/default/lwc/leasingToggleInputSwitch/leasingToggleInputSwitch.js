import { LightningElement, api } from 'lwc';

export default class LeasingToggleInputSwitch extends LightningElement {
  @api label;
  @api name;
  @api amountPlaceholder;
  @api percentPlaceholder;

  @api type = 'Amount';   
  @api value = 0;        

  get discountOptions() {
    return [
      { label: 'Amount', value: 'Amount' },
      { label: 'Percentage', value: 'Percentage' }
    ];
  }

  get isPercent() {
    return this.type === 'Percentage';
  }

  handleTypeChange(event) {
    this.type = event.detail.value;
    this.value = 0; 
    this.sendValue();
  }

  handleInputChange(event) {
    this.value = event.target.value;
    this.sendValue();
  }

  sendValue() {
    const myCustomEvent = new CustomEvent('valuechange', {
      detail: {
        name: this.name,
        type: this.type,
        value: this.value ?? 0
      }
    });
    this.dispatchEvent(myCustomEvent);
  }
}