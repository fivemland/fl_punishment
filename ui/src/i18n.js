import { init, addMessages, getLocaleFromNavigator } from 'svelte-i18n';

import en from './locales/en.json';
import hu from './locales/hu.json';

addMessages('en', en);
addMessages('hu', hu);

init({
  fallbackLocale: 'en',
  initialLocale: getLocaleFromNavigator(),
});
