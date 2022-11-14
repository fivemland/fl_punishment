<script>
  import ComservInfo from './components/ComservInfo.svelte';
  import AdminPanel from './components/AdminPanel.svelte';
  import JailInfo from './components/JailInfo.svelte';
  import { onMount } from 'svelte';
  import { locale } from 'svelte-i18n';

  onMount(async () => {
    const resp = await fetch(`https://${GetParentResourceName()}/getLocale`);
    const { locale: _locale } = await resp.json();

    locale.set(_locale);
  });
</script>

<main>
  <ComservInfo />
  <AdminPanel />
  <JailInfo />
</main>
