package org.osflash.vanilla.reflection.as3commons
{
	import org.as3commons.lang.ClassUtils;
	import org.as3commons.reflect.Accessor;
	import org.as3commons.reflect.Field;
	import org.as3commons.reflect.Metadata;
	import org.as3commons.reflect.MetadataArgument;
	import org.as3commons.reflect.Method;
	import org.as3commons.reflect.Parameter;
	import org.as3commons.reflect.Type;
	import org.as3commons.reflect.Variable;
	import org.osflash.vanilla.InjectionDetail;
	import org.osflash.vanilla.reflection.IInjectionMapSpi;
	import org.osflash.vanilla.reflection.IReflectionMapFactory;

	/**
	 * Provides an implementation of the Vanialla IReflector interface for aS3Commons-reflect.
	 */
	public class AS3CommonsReflectionMapFactory implements IReflectionMapFactory
	{
		private static const METADATA_TAG : String = "Marshall";
		private static const METADATA_FIELD_KEY : String = "field";
		private static const METADATA_TYPE_KEY : String = "type";
		
		private var injectionMap:IInjectionMapSpi;
		
		public function create(targetType : Class, injectionMap : IInjectionMapSpi) : void
		{
			this.injectionMap = injectionMap;
			
			const type : Type = Type.forClass(targetType);
			
			extractFields(type);
			extractMethods(type);
			extractCtor(type);
		}

		private function extractFields(type : Type) : void
		{
			const numFields : uint = type.fields.length;
			
			for (var i : uint = 0; i < numFields; i++) 
			{
				const field : org.as3commons.reflect.Field = type.fields[i];
				if (canAccess(field)) {
					const vectorType : Class = (field.type.parameters) ? field.type.parameters[0] : null;
					const metadataTags : Vector.<Metadata> = extractMetadataTags(field.metadata);
					const metadataProvider : MetadataProvider = new MetadataProvider(metadataTags);
					const fieldMetadataEntries : Vector.<MetadataArgument> = metadataProvider.getMetadataArguments(METADATA_TAG);
					const arrayTypeHint : Class = extractArrayTypeHint(vectorType, fieldMetadataEntries);
					const sourceFieldName : String = extractFieldName(field.name, fieldMetadataEntries);
					
					injectionMap.addField(field.name, new InjectionDetail(sourceFieldName, field.type.clazz, false, arrayTypeHint));
				}
			}
		}
		
		private function extractMethods(type : Type) : void
		{
			const numMethods : uint = type.methods.length;
			
			for (var i : uint = 0; i < numMethods; i++)
			{
				const method : org.as3commons.reflect.Method = type.methods[i];
				
				// If the method has not been annotated then we can skip over it.
				if (method.metadata.length) {
					const metadataTags : Vector.<Metadata> = extractMetadataTags(method.metadata);
					const metadataProvider : MetadataProvider = new MetadataProvider(metadataTags);
					const metadataArgs : Vector.<MetadataArgument> = metadataProvider.getMetadataArguments(METADATA_TAG);
					
					if (metadataArgs == null) {
						continue;
					}
					
					const numArgs : uint = metadataArgs.length;
					for (var j : uint = 0; j < numArgs; j++) {
						if (metadataArgs[j].key == METADATA_FIELD_KEY) {
							const param : Parameter = method.parameters[j];
							const arrayTypeHint : Class = extractArrayTypeHint(param.type.clazz, metadataArgs);
							injectionMap.addMethod(method.name, new InjectionDetail(metadataArgs[j].value, param.type.clazz, false, arrayTypeHint));
						}
					}
				}
			}
		}

		private function extractCtor(type : Type) : void
		{
			// If there's no metadata, we can't marshall anything.
			if (!type.metadata.length)
				return;
			
			const metadataTags : Vector.<Metadata> = extractMetadataTags(type.metadata);
			const metadataProvider : MetadataProvider = new MetadataProvider(metadataTags);
			const metadataArgs : Vector.<MetadataArgument> = metadataProvider.getMetadataArguments(METADATA_TAG);
			const parameters: Array = type.constructor.parameters;
			const numArgs : uint = metadataArgs.length;
			
			for (var i : uint = 0; i < numArgs; i++) {
				if (metadataArgs[i].key == METADATA_FIELD_KEY) {
					const param : Parameter = parameters[i];
					const arrayTypeHint : Class = extractArrayTypeHint(param.type.clazz, metadataArgs);		// No typeHint metadata on ctors, yet.
					injectionMap.addConstructorField(new InjectionDetail(metadataArgs[i].value, param.type.clazz, true, arrayTypeHint));
				}
			}
		}

		private function extractMetadataTags(metadataTags : Array) : Vector.<Metadata>
		{
			const result : Vector.<Metadata> = new Vector.<Metadata>();
			const numTags : uint = metadataTags.length;
			
			for (var i : uint = 0; i < numTags; i++) {
				const metadataTag : Metadata = metadataTags[i];
				
				// Ignore private Metadata Tags.
				if (metadataTag.name.charAt(0) != "_") {
					result.push(metadataTag);
				}
			}
			
			return result;
		}
		
		private function canAccess(field : org.as3commons.reflect.Field) : Boolean
		{
			if (field is org.as3commons.reflect.Variable) {
				return true;
			}
			else if (field is Accessor) {
				return (field as Accessor).writeable;
			}
			return false;
		}		

		private function extractFieldName(fieldName : String, metadataArgs : Vector.<MetadataArgument>) : String
		{
			// See if a taget fieldName has been defined in the Metadata.
			if (metadataArgs) {
				const numArgs : uint = metadataArgs.length;
				for (var i : uint = 0; i < numArgs; i++) {
					if (metadataArgs[i].key == METADATA_FIELD_KEY) {
						return metadataArgs[i].value;
					}
				}
			}
			
			// Assume it's a 1 to 1 mapping.
			return fieldName;
		}

		private function extractArrayTypeHint(vectorType : Class, metadataArgs : Vector.<MetadataArgument> = null) : Class
		{
			// Vectors carry their own type hint.
			if (vectorType) {
				return vectorType;
			}
			
			// Otherwise we will look for some "type" metadata, if it was defined.
			else if (metadataArgs) {
				const numArgs : uint = metadataArgs.length;
				for (var i : uint = 0; i < numArgs; i++) {
					if (metadataArgs[i].key == METADATA_TYPE_KEY) {
						return ClassUtils.forName(metadataArgs[i].value);
					}
				}
			}
			
			// No type hint.
			return null;
		}
	}
}
