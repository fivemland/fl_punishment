<script>
  import { _ } from 'svelte-i18n';
  import InfoBar from './InfoBar.svelte';

  let jail = false;

  window.addEventListener('message', ({ data }) => {
    if (data.jail !== undefined) {
      jail = data.jail;
    }
  });

  $: formatedDate = jail ? new Date((jail.start || 0) * 1000).toLocaleString('en-GB') : false;
</script>

{#if jail && typeof jail === 'object'}
  <main id="infopanel" class="bg-gray-700 p-2 rounded-xl select-none">
    <div class="text-center font-bold mb-2">{$_('jail')}</div>

    <InfoBar title={$_('time_left')} value={`${(jail.all || 0) - (jail.count || 0)} ${$_('minutes')}`} />
    <InfoBar title={$_('all_time')} value={`${jail.all} ${$_('minutes')}`} />
    <InfoBar title={$_('reason')} value={jail.reason} />
    <InfoBar title={$_('admin')} value={jail.admin ? jail.admin.name : $_('unknown')} />
    <InfoBar title={$_('start_date')} value={formatedDate} />
  </main>
{/if}
