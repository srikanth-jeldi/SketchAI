# Collections — 0.8.0+15

The default All designs view exposes 3,094 unique pages with automatic scroll loading. Studio has Kids 364, Intermediate 724 (including shared easy pages suitable for adults), and Advanced 366. Its unique total remains 1,094; Original collection provides all 2,000 legacy pages. All designs deduplicates shared pages by ID. Categories and available difficulty filters derive from matching content and show counts. See [current content scope](RELEASE_0_8_0.md).

## Historical 0.4.0+6 behaviour

Gallery now starts in Kids / Easy. Both Kids and Adults start on Easy whenever switching collections; category selection resets so stale categories cannot hide the new collection. Search applies within the selected collection and difficulty. Saved sketches remain on Home.

Kids restores 30 selected original procedural pages (three variants in each of ten families), with bold outlines and named bright colours. Difficulty for these pages is based on closed-region count: at most 45 Easy, at most 90 Medium, otherwise Detailed. This is a small selected collection, not 2,000 bespoke illustrations. Some filter/category combinations have no designs and show the empty-result message.

Adults adds six code-native vector masters: Olive & clay, Stillwater sunset and Lotus calm in Easy; Garden rhythm, Mountain morning and Petal harmony in Medium. The three Medium designs extend the three Easy compositions with more areas. The six approved detailed raster illustrations remain under Adults / Detailed. Simple adult pages have 6–22 colour areas, matching colour samples and curated named palettes. All use the existing fill/brush/save/export/applause flow.

IDs for legacy pages and premium artwork remain unchanged. New adult pages use permanent adult_0 through adult_5 IDs. Their closed paths and broad areas avoid the fine raster masks needed by the detailed collection. Android testing APK built locally; physical device usability and iOS builds remain unverified.

Validation covers collection counts, default Easy, switching to Adults / Detailed and opening artwork, new page save roundtrips, and rendering the six simple adult previews. Preview: previews/simple-adult-designs.png.
