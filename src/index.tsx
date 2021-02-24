import { NativeModules } from 'react-native';

type SuperpoweredType = {
  multiply(a: number, b: number): Promise<number>;
};

const { Superpowered } = NativeModules;

export default Superpowered as SuperpoweredType;
