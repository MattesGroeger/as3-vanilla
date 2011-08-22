package org.osflash.vanilla
{
	import flash.utils.getQualifiedClassName;
	import org.as3commons.lang.ClassUtils;
	import org.as3commons.lang.ObjectUtils;
	import org.osflash.vanilla.reflection.IReflectionMapFactory;
	import org.osflash.vanilla.reflection.as3commons.AS3CommonsReflectionMapFactory;

	
	public class Vanilla
	{
		private var _reflector : IReflectionMapFactory;
		
		public function Vanilla(reflector : IReflectionMapFactory = null) 
		{
			_reflector = reflector || new AS3CommonsReflectionMapFactory();
		}
		
		/**
		 * Attempts to extract properties from the supplied source object into an instance of the supplied targetType.
		 * 
		 * @param source		Object which contains properties that you wish to transfer to a new instance of the 
		 * 						supplied targetType Class.
		 * @param targetType	The target Class of which an instance will be returned.
		 * @return				An instance of the supplied targetType containing all the properties extracted from
		 * 						the supplied source object.
		 */
		public function extract(source : Object, targetType : Class) : *
		{
			// Catch the case where we've been asked to extract a value which is already of the intended targetType;
			// this can often happen when Vanilla is recursing, in which case there is nothing to do.
			if (source is targetType) {
				return source;
			}
			
			// Construct an InjectionMap which tells us how to inject fields from the source object into 
			// the Target class.
			const injectionMap : InjectionMap = new InjectionMap();
			_reflector.create(targetType, injectionMap);
			
			// Create a new isntance of the targetType; and then inject the values from the source object into it
			const target : * = instantiate(targetType, fetchConstructorArgs(source, injectionMap.getConstructorFields()));
			injectFields(source, target, injectionMap);
			injectMethods(source, target, injectionMap);
			
			return target;
		}

		private function fetchConstructorArgs(source : Object, constructorFields : Vector.<InjectionDetail>) : Array
		{
			const result : Array = [];
			for (var i : uint = 0; i < constructorFields.length; i++) {
				result.push(extractValue(source, constructorFields[i]));
			}
			return result;
		}

		private function injectFields(source : Object, target : *, injectionMap : InjectionMap) : void
		{
			const fieldNames : Vector.<String> = injectionMap.getFieldNames();
			for each (var fieldName : String in fieldNames) {
				target[fieldName] = extractValue(source, injectionMap.getField(fieldName));
			}
		}
		
		private function injectMethods(source : Object, target : *, injectionMap : InjectionMap) : void
		{
			const methodNames : Vector.<String> = injectionMap.getMethodsNames();
			for each (var methodName : String in methodNames)
			{
				const values : Array = [];
				for each (var injectionDetail : InjectionDetail in injectionMap.getMethod(methodName)) {
					values.push(extractValue(source, injectionDetail));
				}
				(target[methodName] as Function).apply(null, values);
			}
		}

		private function extractValue(source : Object, injectionDetail : InjectionDetail) : *
		{
			var value : * = source[injectionDetail.name];
			
			// Is this a required injection?
			if (injectionDetail.isRequired && value === undefined) {
				throw new MarshallingError("Required value " + injectionDetail + " does not exist in the source object.", MarshallingError.MISSING_REQUIRED_FIELD);
			}
			
			if (value) 
			{
				// automatically coerce simple types.
				if (!ObjectUtils.isSimple(value)) {
					value = extract(value, injectionDetail.type);
				}
				
				// Collections are harder, we need to coerce the contents.
				else if (value is Array) {
					if(isVector(injectionDetail.type)) {
						value = extractVector(value, injectionDetail.type, injectionDetail.arrayTypeHint);
					}
					else if (injectionDetail.arrayTypeHint) {
						value = extractTypedArray(value, injectionDetail.arrayTypeHint);
					}					
				}
				
				// refuse to allow any automatic coercing to occur.
				if (!(value is injectionDetail.type)) {
					throw new MarshallingError("Could not coerce `" + injectionDetail.name + "` (value: " + value + " <" + getQualifiedClassName(value) + "]>) from source object to " + injectionDetail.type + " on target object", MarshallingError.TYPE_MISMATCH);
				}
			}
			
			return value;
		}

		private function extractTypedArray(source : Array, targetClassType : Class) : Array
		{
			const result : Array = new Array(source.length);
			for (var i : uint = 0; i < source.length; i++) {
				result[i] = extract(source[i], targetClassType);
			}
			return result;
		}

		private function extractVector(source : Array, targetVectorClass : Class, targetClassType : Class) : *
		{
			const result : * = ClassUtils.newInstance(targetVectorClass);
			for (var i : uint = 0; i < source.length; i++) {
				result[i] = extract(source[i], targetClassType);
			}
			return result;
		}
		

		private function instantiate(targetType : Class, ctorArgs : Array) : *
		{
			return ClassUtils.newInstance(targetType, ctorArgs);
		}

		private function isVector(obj : *) : Boolean 
		{
    		return (getQualifiedClassName(obj).indexOf('__AS3__.vec::Vector') == 0);
		}
	}
}
