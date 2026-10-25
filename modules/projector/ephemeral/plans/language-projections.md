# Language projections and the shared wire contract

The project owns its language backends: JavaScript/JSDoc and TypeScript first, Swift structs later, and Kotlin data classes later for Android. A public grammar/plugin SDK is not a requirement. Internal shared mapping information remains necessary for consistent codecs, naming and generation caches.

JSON fields use canonical JavaScript lowerCamelCase. Parsing JSON into JavaScript yields the same property names used by the JS/TS declarations; there is no additional property-renaming codec. JSON parsing/stringifying and typed validation remain separate necessary operations.

Swift and Kotlin declarations follow their own language conventions for types, properties and keywords. They do not inherit a JavaScript identifier restriction or require per-field naming metadata from the author. Generate serialization key bindings when a target-language spelling differs from the canonical JSON key. Check collisions in both the wire namespace and each target-language namespace. Keep default enum/tag wire labels shared, independent of how a language spells its enum members.

Language-idiomatic declarations do not select wire presence semantics. Future decoders must distinguish a missing optional key from a forbidden explicit null, and preserve required nullable keys, even when the language's default serializer conflates them. Serialization-library selection is deferred with the relevant backend.

Kotlin's preferred record form is a data class with constructor properties. Its [documented requirements](https://kotlinlang.org/docs/data-classes.html) include at least one primary-constructor parameter; empty-record representation therefore needs an explicit backend decision when Kotlin is implemented. This does not remove empty records from the shared mapping now. Naming references: [Swift API guidelines](https://www.swift.org/documentation/api-design-guidelines/) and [Kotlin coding conventions](https://kotlinlang.org/docs/coding-conventions.html).

The Android discussion does not select a deployment architecture. Android can load packaged native shared libraries and Kotlin can call native code through [JNI](https://developer.android.com/ndk/guides/jni-tips); a Zig C-ABI core could be embedded behind an adapter. A remote service is another option. Kotlin declaration generation alone implements neither JNI bindings nor a networking client. No Android build/device execution has been proved here; the pinned Zig source recognizes Android ABI targets, which is narrower evidence than a working application.

Emit ordinary language modules/files without TypeScript barrels. Consumers can import the generated module directly.
